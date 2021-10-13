//
//  HTTPClient+Post.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 13/10/21.
//

import Foundation

public protocol HTTPClientPostProtocol {
    // No JSON Parse
    func post<T: Encodable>(url: String, body: T?, headers: [String:String]?, completion: @escaping CompletionHandler<Data,Data>)
    func post(request: URLRequest, completion: @escaping CompletionHandler<Data,Data>)
}

extension HTTPClient: HTTPClientPostProtocol {
    public func post<T>(url: String, body: T?, headers: [String : String]?, completion: @escaping CompletionHandler<Data, Data>) where T : Encodable {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: body) {
            post(request: request, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func post(request: URLRequest, completion: @escaping CompletionHandler<Data, Data>) {
        _ = makeRequest(request: request, completion: completion)
    }
    
    
}
