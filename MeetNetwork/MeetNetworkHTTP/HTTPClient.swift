//
//  MeetNetworkHTTPClient.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 16/8/21.
//

import Foundation

public typealias CompletionHandler<T,E> = (HTTPResult<T,E>?) -> Void

public protocol HTTPClientProtocol: HTTPClientGetProtocol, HTTPClientPostProtocol {
    
}

public class HTTPClient: HTTPClientProtocol {
    
    public static let shared = HTTPClient()
    
    private init() {
        
    }
    
    internal func getSession() -> URLSession {
        return URLSession.shared
    }
    
    // MARK: Request
    
    internal func makeRequest(request: URLRequest, completion: @escaping CompletionHandler<Data,Data>) -> URLSessionDataTask {
        let session = getSession()
        print("\(HTTPUtils.getLogName()): makeRequest - \(request.httpMethod ?? "?") - \(request.url?.absoluteString ?? "?")")
        
        let dataTask = session.dataTask(with: request) { [weak self] data, urlResponse, error in
            var body = ""
            if let data = data {
                body = String(decoding: data, as: UTF8.self)
                print("\(HTTPUtils.getLogName()): response - \(body)")
            }
            let status = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
            
            if error != nil {
                self?.callCompletionHandlerInMainThread(result: .failure(data, .clientError, status, body), completion: completion)
            } else {
                guard let httpResponse = urlResponse as? HTTPURLResponse,
                      httpResponse.status?.responseType == .success else {
                    // Server error
                    self?.callCompletionHandlerInMainThread(result: .failure(data, .serverError, status, body), completion: completion)
                    return
                }
                
                self?.callCompletionHandlerInMainThread(result: .success(data), completion: completion)
            }
        }
        
        dataTask.resume()
        return dataTask
    }
}
