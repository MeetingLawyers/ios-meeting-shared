//
//  HTTPClient+Get.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 13/10/21.
//

import Foundation

public protocol HTTPClientGetProtocol {
    // No JSON Parse
    func get(url: String, params: [String: String]?, headers: [String:String]?, clearCache: Bool, completion: @escaping RequestCompletionHandler<Data,Data>)
    func get<T: Encodable>(url: String, params: T?, headers: [String:String]?, clearCache: Bool, completion: @escaping RequestCompletionHandler<Data,Data>)
    func get(request: URLRequest, clearCache: Bool, completion: @escaping RequestCompletionHandler<Data,Data>)
    // JSON Parse OK Response
    func get<OKResponse: Decodable>(url: String, params: [String: String]?, headers: [String:String]?, responseModel: OKResponse.Type, clearCache: Bool, completion: @escaping RequestCompletionHandler<OKResponse,Data>)
    func get<OKResponse: Decodable,T: Encodable>(url: String, params: T?, headers: [String:String]?, responseModel: OKResponse.Type, clearCache: Bool, completion: @escaping RequestCompletionHandler<OKResponse,Data>)
    func get<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, clearCache: Bool, completion: @escaping RequestCompletionHandler<OKResponse,Data>)
    // JSON Parse OK and KO Responses
    func get<OKResponse: Decodable,KOResponse: Decodable>(url: String, params: [String: String]?, headers: [String:String]?, responseModel: OKResponse.Type, errorModel: KOResponse.Type, clearCache: Bool, completion: @escaping RequestCompletionHandler<OKResponse,KOResponse>)
    func get<OKResponse: Decodable,KOResponse: Decodable,T: Encodable>(url: String, params: T?, headers: [String:String]?, responseModel: OKResponse.Type, errorModel: KOResponse.Type, clearCache: Bool, completion: @escaping RequestCompletionHandler<OKResponse,KOResponse>)
    func get<OKResponse: Decodable,KOResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, errorModel: KOResponse.Type, clearCache: Bool, completion: @escaping RequestCompletionHandler<OKResponse,KOResponse>)
}

extension HTTPClient: HTTPClientGetProtocol {
    
    // MARK: - No JSON Parse
    public func get(url: String, params: [String : String]? = nil, headers: [String : String]? = nil, clearCache: Bool = false, completion: @escaping RequestCompletionHandler<Data,Data>) {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, clearCache: clearCache, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<T: Encodable>(url: String, params: T?, headers: [String : String]?, clearCache: Bool = false, completion: @escaping RequestCompletionHandler<Data, Data>) {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, clearCache: clearCache, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get(request: URLRequest, clearCache: Bool = false, completion: @escaping RequestCompletionHandler<Data,Data>) {
        _ = makeRequest(request: request, clearCache: clearCache, completion: completion)
    }
    
    // MARK: - JSON Parse OK Response
    
    public func get<OKResponse>(url: String, params: [String : String]? = nil, headers: [String : String]? = nil, responseModel: OKResponse.Type, clearCache: Bool = false, completion: @escaping RequestCompletionHandler<OKResponse, Data>) where OKResponse : Decodable {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, responseModel: responseModel, clearCache: clearCache, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<OKResponse: Decodable,T: Encodable>(url: String, params: T?, headers: [String : String]?, responseModel: OKResponse.Type, clearCache: Bool = false, completion: @escaping RequestCompletionHandler<OKResponse, Data>) {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, responseModel: responseModel, clearCache: clearCache, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<OKResponse>(request: URLRequest, responseModel: OKResponse.Type, clearCache: Bool = false, completion: @escaping RequestCompletionHandler<OKResponse, Data>) where OKResponse : Decodable {
        _ = makeRequest(request: request, clearCache: clearCache, completion: { result in
            switch result {
            case let .success(data):
                self.handleDataTaskResponse(data: data, completion: completion)
            case let .failure(data, error, status, body):
                self.handleDataTaskError(data: data, httpError: error, status: status, body: body, completion: completion)
            default: break
            }
        })
    }
    
    // MARK: - JSON Parse OK and KO Responses
    
    public func get<OKResponse, KOResponse>(url: String, params: [String : String]? = nil, headers: [String : String]? = nil, responseModel: OKResponse.Type, errorModel: KOResponse.Type, clearCache: Bool = false, completion: @escaping RequestCompletionHandler<OKResponse, KOResponse>) where OKResponse : Decodable, KOResponse : Decodable {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, responseModel: responseModel, errorModel: errorModel, clearCache: clearCache, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<OKResponse: Decodable, KOResponse: Decodable, T: Encodable>(url: String, params: T?, headers: [String : String]?, responseModel: OKResponse.Type, errorModel: KOResponse.Type, clearCache: Bool = false, completion: @escaping RequestCompletionHandler<OKResponse, KOResponse>) {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, responseModel: responseModel, errorModel: errorModel, clearCache: clearCache, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<OKResponse, KOResponse>(request: URLRequest, responseModel: OKResponse.Type, errorModel: KOResponse.Type, clearCache: Bool = false, completion: @escaping RequestCompletionHandler<OKResponse, KOResponse>) where OKResponse : Decodable, KOResponse : Decodable {
        _ = makeRequest(request: request, clearCache: clearCache, completion: { result in
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
