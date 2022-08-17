//
//  HTTPClient+PutCombine.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 27/7/22.
//

import Foundation
import Combine

public protocol HTTPClientPutCombineProtocol {
    // No JSON Parse
    func put(url: String, headers: [String:String]?) -> AnyPublisher<HTTPClient.Output, HTTPError>
    func put<T: Encodable>(url: String, body: T?, headers: [String:String]?) -> AnyPublisher<HTTPClient.Output, HTTPError>
    func put(request: URLRequest) -> AnyPublisher<HTTPClient.Output, HTTPError>
    // JSON Parse OK Response
    func put<OKResponse: Decodable,T: Encodable>(url: String, body: T?, headers: [String:String]?, responseModel: OKResponse.Type) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError>
    func put<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError>
}

extension HTTPClient {
    // No JSON Parse
    public func put(url: String, headers: [String : String]? = nil) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        if let request = createURLRequest(url: url, method: .put, headers: headers, parameters: nil) {
            return put(request: request)
        }
        
        return Fail(error: .createRequest).eraseToAnyPublisher()
    }
    
    public func put<T: Encodable>(url: String, body: T?, headers: [String : String]?) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        if let request = createURLRequest(url: url, method: .put, headers: headers, parameters: body) {
            return put(request: request)
        }
        
        return Fail(error: .createRequest).eraseToAnyPublisher()
    }
    
    public func put(request: URLRequest) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        return makeRequest(request: request)
    }
    
    // JSON Parse OK Response
    public func put<OKResponse: Decodable,T: Encodable>(url: String, body: T?, headers: [String:String]?, responseModel: OKResponse.Type) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError> {
        if let request = createURLRequest(url: url, method: .put, headers: headers, parameters: body) {
            return put(request: request, responseModel: responseModel)
        }
        
        return Fail(error: .createRequest).eraseToAnyPublisher()
    }
    
    public func put<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError> {
        return put(request: request)
                .tryMap({ element in
                    let decodedResponse = try JSONDecoder().decode(OKResponse.self, from: element.data)
                    return HTTPClient.DecodedOutput(decodedResponse, element.response)
                })
                .mapError({ error in
                    switch error {
                    case is Swift.DecodingError:
                        return .JSONParseError
                    default:
                        return .unknownError
                    }
                })
                .eraseToAnyPublisher()
    }
}
