//
//  HTTPClient+GetCombine.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 1/2/22.
//

import UIKit
import Combine

public protocol HTTPClientGetCombineProtocol {
    // No JSON Parse
    func get(url: String, params: [String: String]?, headers: [String:String]?, clearCache: Bool) -> AnyPublisher<HTTPClient.Output, HTTPError>
    func get<T: Encodable>(url: String, params: T?, headers: [String:String]?, clearCache: Bool) -> AnyPublisher<HTTPClient.Output, HTTPError>
    func get(request: URLRequest, clearCache: Bool) -> AnyPublisher<HTTPClient.Output, HTTPError>
    // JSON Parse OK Response
    func get<OKResponse: Decodable>(url: String, params: [String: String]?, headers: [String:String]?, responseModel: OKResponse.Type, clearCache: Bool) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError>
    func get<OKResponse: Decodable,T: Encodable>(url: String, params: T?, headers: [String:String]?, responseModel: OKResponse.Type, clearCache: Bool) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError>
    func get<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, clearCache: Bool) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError>
}

extension HTTPClient: HTTPClientGetCombineProtocol {
    // MARK: - No JSON Parse
    public func get(url: String, params: [String : String]? = nil, headers: [String : String]? = nil, clearCache: Bool = false) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            return get(request: request, clearCache: clearCache)
        }
        
        return Fail(error: .createRequest).eraseToAnyPublisher()
    }
    
    public func get<T: Encodable>(url: String, params: T?, headers: [String : String]?, clearCache: Bool = false) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            return get(request: request, clearCache: clearCache)
        }
        
        return Fail(error: .createRequest).eraseToAnyPublisher()
    }
    
    public func get(request: URLRequest, clearCache: Bool = false) -> AnyPublisher<HTTPClient.Output, HTTPError> {
        return makeRequest(request: request, clearCache: clearCache)
    }
    
    // MARK: - JSON Parse OK Response

    public func get<OKResponse: Decodable>(url: String, params: [String : String]? = nil, headers: [String : String]? = nil, responseModel: OKResponse.Type, clearCache: Bool = false) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError> {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            return get(request: request, responseModel: responseModel, clearCache: clearCache)
        }

        return Fail(error: .createRequest).eraseToAnyPublisher()
    }

    public func get<OKResponse: Decodable,T: Encodable>(url: String, params: T?, headers: [String : String]?, responseModel: OKResponse.Type, clearCache: Bool = false) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError> {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            return get(request: request, responseModel: responseModel, clearCache: clearCache)
        }

        return Fail(error: .createRequest).eraseToAnyPublisher()
    }

    public func get<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, clearCache: Bool = false) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError> {
        return makeRequest(request: request, clearCache: clearCache)
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
