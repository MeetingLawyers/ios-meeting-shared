//
//  HTTPClient+Utils.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 13/10/21.
//

import Foundation

internal protocol HTTPClientUtilsProtocol {
    func createURLRequest(url: String, method: HTTPMethod, headers: [String: String]?, parameters: [String: String]?) -> URLRequest?
    func createURLRequest<T: Encodable>(url: String, method: HTTPMethod, headers: [String: String]?, parameters: T?) -> URLRequest?
    func callCompletionHandlerInMainThread<T,E>(result: HTTPResult<T,E>, completion: @escaping RequestCompletionHandler<T,E>)
    func makeRequest(request: URLRequest, clearCache: Bool, completion: @escaping RequestCompletionHandler<Data,Data>) -> URLSessionDataTask
}

extension HTTPClient: HTTPClientUtilsProtocol {
    internal func createURLRequest(url: String, method: HTTPMethod, headers: [String: String]?, parameters: [String: String]?) -> URLRequest? {
        if let url = URL(string: url) {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            if let headers = headers {
                addRequestHeaders(request: &request, headers: headers)
            }
            if let params = parameters {
                addGetParameters(request: &request, parameters: params)
            }
            
            return request
        }
        
        return nil
    }
    
    internal func createURLRequest<T: Encodable>(url: String, method: HTTPMethod, headers: [String: String]?, parameters: T?) -> URLRequest? {
        var request = createURLRequest(url: url, method: method, headers: headers, parameters: nil)
        if request != nil {
            if method == .get {
                addGetParameters(request: &request!, parameters: parameters)
            } else if method == .post || method == .put {
                addJsonBodyParameters(request: &request!, parameters: parameters)
            }
        }
        return request
    }
    
    internal func callCompletionHandlerInMainThread<T,E>(result: HTTPResult<T,E>, completion: @escaping RequestCompletionHandler<T,E>) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    internal func makeRequest(request tmpRequest: URLRequest, clearCache: Bool = false, completion: @escaping RequestCompletionHandler<Data,Data>) -> URLSessionDataTask {
        let session = getSession()
        var request = tmpRequest
        print("\(HTTPUtils.getLogName()): makeRequest - \(request.httpMethod ?? "?") - \(request.url?.absoluteString ?? "?")")
        print("\(HTTPUtils.getLogName()): makeRequest - HEADERS: \n\(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody {
            let bodyString = String(decoding: body, as: UTF8.self)
            print("\(HTTPUtils.getLogName()): makeRequest - BODY: \(bodyString)")
        }
        
        if clearCache {
            print("\(HTTPUtils.getLogName()): makeRequest CLEAR CACHE FOR: - \(request.httpMethod ?? "?") - \(request.url?.absoluteString ?? "?")")
            session.configuration.urlCache?.removeCachedResponse(for: request)
            request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        }
        
        let dataTask = session.dataTask(with: request) { [weak self] data, urlResponse, error in
            var body = ""
            let status = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
            
            if let httpResponse = urlResponse as? HTTPURLResponse,
               let date = httpResponse.value(forHTTPHeaderField: "Date") {
                print("\(HTTPUtils.getLogName()): RESPONSE \(status) - DATE: \(date)")
            }
            
            if let data = data {
                body = String(decoding: data, as: UTF8.self)
                print("\(HTTPUtils.getLogName()): RESPONSE \(status) - BODY: \(body)")
            }
            
            if let error = error {
                // Client error
                if let error = error as NSError?, error.domain == NSURLErrorDomain {
                    if error.code == NSURLErrorNotConnectedToInternet {
                        self?.callCompletionHandlerInMainThread(result: .failure(data, .noInternet, status, body), completion: completion)
                        return
                    } else if error.code == NSURLErrorTimedOut {
                        self?.callCompletionHandlerInMainThread(result: .failure(data, .timeout, status, body), completion: completion)
                        return
                    }
                }
                self?.callCompletionHandlerInMainThread(result: .failure(data, .clientError, status, body), completion: completion)
                return
            } else {
                guard let httpResponse = urlResponse as? HTTPURLResponse,
                      httpResponse.status?.responseType == .success else {
                    // Server error
                    self?.callCompletionHandlerInMainThread(result: .failure(data, .serverError, status, body), completion: completion)
                    return
                }
                
                self?.callCompletionHandlerInMainThread(result: .success(data), completion: completion)
                return
            }
        }
        
        dataTask.resume()
        return dataTask
    }
}

extension HTTPClient {
    internal func addRequestHeaders(request: inout URLRequest, headers: [String: String]) {
        for (header, value) in headers {
            request.addValue(value, forHTTPHeaderField: header)
        }
    }
    
    internal func addGetParameters(request: inout URLRequest, parameters: [String: String]) {
        if let stringURL = request.url?.absoluteString,
           var url = URLComponents(string: stringURL) {
            
            var queryItems = [URLQueryItem]()

            for (param, value) in parameters {
                queryItems.append(URLQueryItem(name: param, value: value))
            }
            
            url.queryItems = queryItems

            url.percentEncodedQuery = url.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            
            request.url = url.url
        }
    }
    
    internal func addGetParameters<T: Encodable>(request: inout URLRequest, parameters: T) {
        if let stringURL = request.url?.absoluteString,
           var url = URLComponents(string: stringURL) {
            
            var queryItems = [URLQueryItem]()
            
            if let data = try? JSONEncoder().encode(parameters) {
                if let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                    for (param, value) in dictionary {
                        queryItems.append(URLQueryItem(name: param, value: "\(value)"))
                    }
                    
                    url.queryItems = queryItems

                    url.percentEncodedQuery = url.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
                }
            }
            
            request.url = url.url
        }
    }
    
    internal func addJsonBodyParameters<T: Encodable>(request: inout URLRequest, parameters: T) {
        // GUARD POST/PUT
        guard request.httpMethod == "POST" || request.httpMethod == "PUT" else {
            return
        }
        
        if let jsonData = try? JSONEncoder().encode(parameters) {
            request.httpBody = jsonData
        }
    }
    
    internal func getSession() -> URLSession {
        if let session = session {
            return session
        }
        
        let configuration = URLSessionConfiguration.default
        
        if let requestTimeout = requestTimeout {
            configuration.timeoutIntervalForRequest = requestTimeout
            configuration.timeoutIntervalForResource = requestTimeout
        }
        
        self.session = URLSession(configuration: configuration,
                                  delegate: self,
                                  delegateQueue: nil)
        return self.session ?? URLSession.shared
    }
    
    // MARK: Handle response
    
    internal func handleDataTaskError<T>(data: Data?, httpError: HTTPError, status: Int, body: String?, completion: @escaping RequestCompletionHandler<T,Data>) {
        self.callCompletionHandlerInMainThread(result: .failure(data, httpError, status, body), completion: completion)
    }
    
    internal func handleDataTaskError<T, E: Decodable>(data: Data?, httpError: HTTPError, status: Int, body: String?, completion: @escaping RequestCompletionHandler<T,E>) {
        // Decode json
        if let data = data, let decodedResponse = try? JSONDecoder().decode(E.self, from: data) {
            self.callCompletionHandlerInMainThread(result: .failure(decodedResponse, httpError, status, body), completion: completion)
            return
        }
        
        var body = ""
        if let data = data {
            body = String(decoding: data, as: UTF8.self)
        }
        
        self.callCompletionHandlerInMainThread(result: .failure(nil, httpError, 0, body), completion: completion)
    }
    
    internal func handleDataTaskResponse<T: Decodable,E>(data: Data?, completion: @escaping RequestCompletionHandler<T,E>) {
        // Decode json
        if let data = data {
            if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
                self.callCompletionHandlerInMainThread(result: .success(decodedResponse), completion: completion)
                return
            } else {
                let body = String(decoding: data, as: UTF8.self)
                self.callCompletionHandlerInMainThread(result: .failure(nil, .JSONParseError, 0, body), completion: completion)
                return
            }
        } else {
            self.callCompletionHandlerInMainThread(result: .success(nil), completion: completion)
        }
    }
}
