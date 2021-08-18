//
//  MeetNetworkHTTPClient.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 16/8/21.
//

import Foundation

public typealias CompletionHandler<T,E> = (HTTPResult<T,E>?) -> Void

public protocol HTTPClientProtocol {
    func get<T,E>(url: String, params: [String: String], headers: [String:String], responseModel: T.Type?, errorModel: E.Type?, completion: @escaping CompletionHandler<T,E>)
    func get<T,E>(request: URLRequest, responseModel: T.Type?, errorModel: E.Type?, completion: @escaping CompletionHandler<T,E>)
}

internal protocol HTTPClientUtilsProtocol {
    func createURLRequest(url: String, method: HTTPMethod) -> URLRequest?
    func addRequestHeaders(request: inout URLRequest, headers: [String: String])
    func addGetParameters(request: inout URLRequest, parameters: [String: String])
    
    func callCompletionHandlerInMainThread<T,E>(result: HTTPResult<T,E>, completion: @escaping CompletionHandler<T,E>)
}

public class HTTPClient {
    
    public static let shared = HTTPClient()
    
    private init() {
        
    }
    
    internal func getSession() -> URLSession {
        return URLSession.shared
    }
}

extension HTTPClient: HTTPClientProtocol {
    
    internal func handleDataTaskError<T,E>(httpError: HTTPError? = nil, data: Data?, response: URLResponse?, error: Error?, completion: @escaping CompletionHandler<T,E>) {
        
    }
    
    internal func handleDataTaskResponse<T,E>(data: Data?, response: URLResponse?, completion: @escaping CompletionHandler<T,E>) {
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.status?.responseType == .success else {
            // Server error
            self.handleDataTaskError(httpError: .serverError, data: data, response: response, error: nil, completion: completion)
            return
        }
        
        // Decode json
        if let data = data {
            let body = String(decoding: data, as: UTF8.self)
            print("\(HTTPUtils.getLogName()): response - \(body)")
            
            if T.self is Data.Type {
                //  T conform Data
                self.callCompletionHandlerInMainThread(result: .success(data as? T), completion: completion)
                return
            }
            
            if T.self is Decodable.Type {
                self.handleDataTaskResponse(data: data, response: response, completion: completion)
            } else {
                self.callCompletionHandlerInMainThread(result: .failure(nil, .responseModelNotConformsDecodable, 0, body), completion: completion)
            }
        } else {
            self.callCompletionHandlerInMainThread(result: .success(nil), completion: completion)
        }
    }
    
    internal func handleDataTaskResponse<T: Decodable,E>(data: Data, response: URLResponse?, completion: @escaping CompletionHandler<T,E>) {
        let body = String(decoding: data, as: UTF8.self)
        
        if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
            self.callCompletionHandlerInMainThread(result: .success(decodedResponse), completion: completion)
            return
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .JSONParseError, 0, body), completion: completion)
            return
        }
    }
    
    internal func makeRequest<T,E>(request: URLRequest, completion: @escaping CompletionHandler<T,E>) -> URLSessionDataTask {
        let session = getSession()
        print("\(HTTPUtils.getLogName()): makeRequest - \(request.httpMethod ?? "?") - \(request.url?.absoluteString ?? "?")")
        
        let dataTask = session.dataTask(with: request) { [weak self] data, urlResponse, error in
            if let error = error {
                self?.handleDataTaskError(data: data, response: urlResponse, error: error, completion: completion)
            } else {
                self?.handleDataTaskResponse(data: data, response: urlResponse, completion: completion)
            }
        }
        
        dataTask.resume()
        return dataTask
    }
    
    public func get<T,E>(url: String, params: [String: String], headers: [String:String], responseModel: T.Type?, errorModel: E.Type?, completion: @escaping CompletionHandler<T,E>) {
        if var request = createURLRequest(url: url, method: .get) {
            addRequestHeaders(request: &request, headers: headers)
            addGetParameters(request: &request, parameters: params)
            get(request: request, responseModel: responseModel, errorModel: errorModel, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<T,E>(request: URLRequest, responseModel: T.Type?, errorModel: E.Type?, completion: @escaping CompletionHandler<T,E>) {
        _ = makeRequest(request: request, completion: completion)
    }
}

extension HTTPClient: HTTPClientUtilsProtocol {
    internal func createURLRequest(url: String, method: HTTPMethod) -> URLRequest? {
        if let url = URL(string: url) {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            return request
        }
        
        return nil
    }
    
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
    
    internal func callCompletionHandlerInMainThread<T,E>(result: HTTPResult<T,E>, completion: @escaping CompletionHandler<T,E>) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}
