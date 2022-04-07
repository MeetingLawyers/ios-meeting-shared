//
//  HTTPClient+Put.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 10/1/22.
//

import Foundation

public protocol HTTPClientPutProtocol {
    // No JSON Parse
    func put(url: String, headers: [String:String]?, completion: @escaping RequestCompletionHandler<Data,Data>)
    func put<T: Encodable>(url: String, body: T?, headers: [String:String]?, completion: @escaping RequestCompletionHandler<Data,Data>)
    func put(request: URLRequest, completion: @escaping RequestCompletionHandler<Data,Data>)
    // JSON Parse OK Response
    func put<OKResponse: Decodable,T: Encodable>(url: String, body: T?, headers: [String:String]?, responseModel: OKResponse.Type, completion: @escaping RequestCompletionHandler<OKResponse,Data>)
    func put<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, completion: @escaping RequestCompletionHandler<OKResponse,Data>)
}

extension HTTPClient: HTTPClientPutProtocol {
    public func put(url: String, headers: [String:String]?, completion: @escaping RequestCompletionHandler<Data,Data>) {
        if let request = createURLRequest(url: url, method: .put, headers: headers, parameters: nil) {
            put(request: request, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func put<T>(url: String, body: T?, headers: [String : String]?, completion: @escaping RequestCompletionHandler<Data, Data>) where T : Encodable {
        if let request = createURLRequest(url: url, method: .put, headers: headers, parameters: body) {
            put(request: request, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func put(request: URLRequest, completion: @escaping RequestCompletionHandler<Data, Data>) {
        _ = makeRequest(request: request, clearCache: true, completion: completion)
    }
    
    // MARK: - JSON Parse OK Response
    
    public func put<OKResponse: Decodable,T: Encodable>(url: String, body: T?, headers: [String : String]?, responseModel: OKResponse.Type, completion: @escaping RequestCompletionHandler<OKResponse, Data>) {
        if let request = createURLRequest(url: url, method: .put, headers: headers, parameters: body) {
            put(request: request, responseModel: responseModel, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func put<OKResponse>(request: URLRequest, responseModel: OKResponse.Type, completion: @escaping RequestCompletionHandler<OKResponse, Data>) where OKResponse : Decodable {
        _ = makeRequest(request: request, clearCache: true, completion: { result in
            switch result {
            case let .success(data, response):
                self.handleDataTaskResponse(data: data, response: response, completion: completion)
            case let .failure(data, error, status, body):
                self.handleDataTaskError(data: data, httpError: error, status: status, body: body, completion: completion)
            default: break
            }
        })
    }
}
