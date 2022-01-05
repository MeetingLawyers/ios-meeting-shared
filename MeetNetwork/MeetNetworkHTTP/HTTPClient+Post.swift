//
//  HTTPClient+Post.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 13/10/21.
//

import Foundation

public protocol HTTPClientPostProtocol {
    // No JSON Parse
    func post<T: Encodable>(url: String, body: T?, headers: [String:String]?, completion: @escaping RequestCompletionHandler<Data,Data>)
    func post(request: URLRequest, completion: @escaping RequestCompletionHandler<Data,Data>)
    // JSON Parse OK Response
    func post<OKResponse: Decodable,T: Encodable>(url: String, body: T?, headers: [String:String]?, responseModel: OKResponse.Type, completion: @escaping RequestCompletionHandler<OKResponse,Data>)
    func post<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, completion: @escaping RequestCompletionHandler<OKResponse,Data>)
}

extension HTTPClient: HTTPClientPostProtocol {
    public func post<T>(url: String, body: T?, headers: [String : String]?, completion: @escaping RequestCompletionHandler<Data, Data>) where T : Encodable {
        if let request = createURLRequest(url: url, method: .post, headers: headers, parameters: body) {
            post(request: request, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func post(request: URLRequest, completion: @escaping RequestCompletionHandler<Data, Data>) {
        _ = makeRequest(request: request, withCache: false, completion: completion)
    }
    
    // MARK: - JSON Parse OK Response
    
    public func post<OKResponse: Decodable,T: Encodable>(url: String, body: T?, headers: [String : String]?, responseModel: OKResponse.Type, completion: @escaping RequestCompletionHandler<OKResponse, Data>) {
        if let request = createURLRequest(url: url, method: .post, headers: headers, parameters: body) {
            post(request: request, responseModel: responseModel, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func post<OKResponse>(request: URLRequest, responseModel: OKResponse.Type, completion: @escaping RequestCompletionHandler<OKResponse, Data>) where OKResponse : Decodable {
        _ = makeRequest(request: request, withCache: false, completion: { result in
            switch result {
            case let .success(data):
                self.handleDataTaskResponse(data: data, completion: completion)
            case let .failure(data, error, status, body):
                self.handleDataTaskError(data: data, httpError: error, status: status, body: body, completion: completion)
            default: break
            }
        })
    }
}
