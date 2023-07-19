//
//  HTTPClient+PostCombine.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 18/10/22.
//

import Foundation
import Combine

public protocol HTTPClientPostCombineProtocol {
    // No JSON Parse
    func post(url: String, headers: [String:String]?) -> AnyPublisher<HTTPClient.Output, HTTPError>
    func post<T: Encodable>(url: String, body: T?, headers: [String:String]?) -> AnyPublisher<HTTPClient.Output, HTTPError>
    func post(request: URLRequest) -> AnyPublisher<HTTPClient.Output, HTTPError>
    // JSON Parse OK Response
    func post<OKResponse: Decodable,T: Encodable>(url: String, body: T?, headers: [String:String]?, responseModel: OKResponse.Type) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError>
    func post<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError>
}

extension HTTPClient {
    // No JSON Parse
    public func post(url: String, headers: [String : String]? = nil) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        if let request = createURLRequest(url: url, method: .post, headers: headers, parameters: nil) {
            return post(request: request)
        }
        
        return Fail(error: .createRequest).eraseToAnyPublisher()
    }
    
    public func post<T: Encodable>(url: String, body: T?, headers: [String : String]?) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        if let request = createURLRequest(url: url, method: .post, headers: headers, parameters: body) {
            return post(request: request)
        }
        
        return Fail(error: .createRequest).eraseToAnyPublisher()
    }
    
    public func post(request: URLRequest) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        return makeRequest(request: request)
    }
    
    // JSON Parse OK Response
    public func post<OKResponse: Decodable,T: Encodable>(url: String, body: T?, headers: [String:String]?, responseModel: OKResponse.Type) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError> {
        if let request = createURLRequest(url: url, method: .post, headers: headers, parameters: body) {
            return post(request: request, responseModel: responseModel)
        }
        
        return Fail(error: .createRequest).eraseToAnyPublisher()
    }
    
    public func post<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError> {
        return post(request: request)
                .tryMap({ element in
                    let decodedResponse = try JSONDecoder().decode(OKResponse.self, from: element.data)
                    return HTTPClient.DecodedOutput(decodedResponse, element.response)
                })
                .mapError({ error in
                    if let error = error as? HTTPError {
                        return error
                    }
                    
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
