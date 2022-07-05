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
    // JSON Parse OK Response
//    func get<OKResponse: Decodable>(url: String, params: [String: String]?, headers: [String:String]?, responseModel: OKResponse.Type, clearCache: Bool) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError>
//    func get<OKResponse: Decodable,T: Encodable>(url: String, params: T?, headers: [String:String]?, responseModel: OKResponse.Type, clearCache: Bool) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError>
//    func get<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, clearCache: Bool) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError>
}

extension HTTPClient: HTTPClientDeleteCombineProtocol {
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
    
    // MARK: - JSON Parse OK Response

    // ⚠️ FALTA TESTEAR ⚠️
//    public func get<OKResponse: Decodable>(url: String, params: [String : String]? = nil, headers: [String : String]? = nil, responseModel: OKResponse.Type, clearCache: Bool = false) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError> {
//        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
//            return get(request: request, responseModel: responseModel, clearCache: clearCache)
//        }
//
//        return Fail(error: .createRequest).eraseToAnyPublisher()
//    }
//
//    public func get<OKResponse: Decodable,T: Encodable>(url: String, params: T?, headers: [String : String]?, responseModel: OKResponse.Type, clearCache: Bool = false) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError> {
//        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
//            return get(request: request, responseModel: responseModel, clearCache: clearCache)
//        }
//
//        return Fail(error: .createRequest).eraseToAnyPublisher()
//    }
//
//    public func get<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, clearCache: Bool = false) -> AnyPublisher<HTTPClient.DecodedOutput<OKResponse>, HTTPError> {
//        return makeRequest(request: request, clearCache: clearCache)
//            .tryMap({ element in
//                let decodedResponse = try JSONDecoder().decode(OKResponse.self, from: element.data)
//                return HTTPClient.DecodedOutput(decodedResponse, element.response)
//            })
//            .mapError({ error in
//                switch error {
//                case is Swift.DecodingError:
//                    return .JSONParseError
//                default:
//                    return .unknownError
//                }
//            })
//            .eraseToAnyPublisher()
//    }
}
