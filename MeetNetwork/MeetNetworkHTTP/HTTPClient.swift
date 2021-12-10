//
//  MeetNetworkHTTPClient.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 16/8/21.
//

import Foundation

public typealias CompletionHandler<T,E> = (HTTPResult<T,E>?) -> Void

public protocol HTTPClientProtocol: HTTPClientGetProtocol, HTTPClientPostProtocol {
    func config(timeout: Double?)
}

public class HTTPClient: HTTPClientProtocol {
    
    public static let shared = HTTPClient()
    
    internal var session: URLSession?
    internal var requestTimeout: Double?
    
    private init() {
        
    }
    
    internal func getSession() -> URLSession {
        if let session = session {
            return session
        }
        if let requestTimeout = requestTimeout {
            let urlconfig = URLSessionConfiguration.default
            urlconfig.timeoutIntervalForRequest = requestTimeout
            urlconfig.timeoutIntervalForResource = requestTimeout
            session = URLSession.init(configuration: urlconfig)
            return session ?? URLSession.shared
        }
        
        session = URLSession.shared
        return session ?? URLSession.shared
    }
    
    // MARK: Request
    
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
    public func config(timeout: Double?) {
        self.requestTimeout = timeout
        self.session = nil
    }
}
