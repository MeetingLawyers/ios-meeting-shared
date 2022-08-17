//
//  HTTPClient+GetCombine.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 1/2/22.
//

import UIKit
import Combine

public protocol HTTPClientDeleteCombineProtocol {
    // No JSON Parse
    func delete(url: String, headers: [String:String]?) -> AnyPublisher<HTTPClient.Output, HTTPError>
    func delete(request: URLRequest) -> AnyPublisher<HTTPClient.Output, HTTPError>
}

extension HTTPClient {
    // MARK: - No JSON Parse
    public func delete(url: String, headers: [String : String]? = nil) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        if let request = createURLRequest(url: url, method: .delete, headers: headers, parameters: nil) {
            return delete(request: request)
        }
        
        return Fail(error: .createRequest).eraseToAnyPublisher()
    }
    
    public func delete(request: URLRequest) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        return makeRequest(request: request)
    }
}
