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
    func callCompletionHandlerInMainThread<T,E>(result: HTTPResult<T,E>, completion: @escaping CompletionHandler<T,E>)
    func makeRequest(request: URLRequest, completion: @escaping CompletionHandler<Data,Data>) -> URLSessionDataTask
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
            } else if method == .post {
                addJsonBodyParameters(request: &request!, parameters: parameters)
            }
        }
        return request
    }
    
    internal func callCompletionHandlerInMainThread<T,E>(result: HTTPResult<T,E>, completion: @escaping CompletionHandler<T,E>) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    internal func makeRequest(request: URLRequest, completion: @escaping CompletionHandler<Data,Data>) -> URLSessionDataTask {
        let session = getSession()
        print("\(HTTPUtils.getLogName()): makeRequest - \(request.httpMethod ?? "?") - \(request.url?.absoluteString ?? "?")")
        print("\(HTTPUtils.getLogName()): makeRequest - HEADERS: \n\(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody {
            let bodyString = String(decoding: body, as: UTF8.self)
            print("\(HTTPUtils.getLogName()): makeRequest - BODY: \(bodyString)")
        }
        
        let dataTask = session.dataTask(with: request) { [weak self] data, urlResponse, error in
            var body = ""
            let status = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
            
            if let data = data {
                body = String(decoding: data, as: UTF8.self)
                print("\(HTTPUtils.getLogName()): RESPONSE \(status) - BODY:    \(body)")
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
}
