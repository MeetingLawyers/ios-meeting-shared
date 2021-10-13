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
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters) {
            request.httpBody = jsonData
        }
    }
    
    internal func callCompletionHandlerInMainThread<T,E>(result: HTTPResult<T,E>, completion: @escaping CompletionHandler<T,E>) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}
