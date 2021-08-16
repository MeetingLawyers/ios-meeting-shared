//
//  MeetNetworkHTTPClient.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 16/8/21.
//

import Foundation

public protocol MeetNetworkHTTPClientProtocol {
    func get<T,E>(responseModel: T.Type, errorModel: E.Type, success: @escaping (T) -> Void, failure: @escaping (E?, Int, String) -> Void) where T: Decodable, E: Decodable
    func post<T,E>(responseModel: T.Type, errorModel: E.Type, success: @escaping (T) -> Void, failure: @escaping (E?, Int, String) -> Void) where T: Decodable, E: Decodable
    func put<T,E>(responseModel: T.Type, errorModel: E.Type, success: @escaping (T) -> Void, failure: @escaping (E?, Int, String) -> Void) where T: Decodable, E: Decodable
    func delete<T,E>(responseModel: T.Type, errorModel: E.Type, success: @escaping (T) -> Void, failure: @escaping (E?, Int, String) -> Void) where T: Decodable, E: Decodable
}

public class MeetNetworkHTTPClient: MeetNetworkHTTPClientProtocol {
    
    public static let shared = MeetNetworkHTTPClient()
    
    private init() {
        
    }
    
    internal func getSession() -> URLSession {
        return URLSession.shared
    }
    
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
    
    internal func makeRequest(request: URLRequest) -> URLSessionDataTask {
        let session = getSession()
        
        let dataTask = session.dataTask(with: request) { data, urlResponse, error in
            // TODO:
        }
        
        dataTask.resume()
        return dataTask
    }
    
    public func get<T, E>(responseModel: T.Type, errorModel: E.Type, success: @escaping (T) -> Void, failure: @escaping (E?, Int, String) -> Void) where T : Decodable, E : Decodable {
        // TODO:
    }
    
    public func post<T, E>(responseModel: T.Type, errorModel: E.Type, success: @escaping (T) -> Void, failure: @escaping (E?, Int, String) -> Void) where T : Decodable, E : Decodable {
        // TODO:
    }
    
    public func put<T, E>(responseModel: T.Type, errorModel: E.Type, success: @escaping (T) -> Void, failure: @escaping (E?, Int, String) -> Void) where T : Decodable, E : Decodable {
        // TODO:
    }
    
    public func delete<T, E>(responseModel: T.Type, errorModel: E.Type, success: @escaping (T) -> Void, failure: @escaping (E?, Int, String) -> Void) where T : Decodable, E : Decodable {
        // TODO:
    }
    
    
}
