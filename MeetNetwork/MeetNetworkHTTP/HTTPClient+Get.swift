//
//  HTTPClient+Get.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 13/10/21.
//

import Foundation

public protocol HTTPClientGetProtocol {
    // No JSON Parse
    func get(url: String, params: [String: String]?, headers: [String:String]?, completion: @escaping CompletionHandler<Data,Data>)
    func get<T: Encodable>(url: String, params: T?, headers: [String:String]?, completion: @escaping CompletionHandler<Data,Data>)
    func get(request: URLRequest, completion: @escaping CompletionHandler<Data,Data>)
    // JSON Parse OK Response
    func get<OKResponse: Decodable>(url: String, params: [String: String]?, headers: [String:String]?, responseModel: OKResponse.Type, completion: @escaping CompletionHandler<OKResponse,Data>)
    func get<OKResponse: Decodable,T: Encodable>(url: String, params: T?, headers: [String:String]?, responseModel: OKResponse.Type, completion: @escaping CompletionHandler<OKResponse,Data>)
    func get<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, completion: @escaping CompletionHandler<OKResponse,Data>)
    // JSON Parse OK and KO Responses
    func get<OKResponse: Decodable,KOResponse: Decodable>(url: String, params: [String: String]?, headers: [String:String]?, responseModel: OKResponse.Type, errorModel: KOResponse.Type, completion: @escaping CompletionHandler<OKResponse,KOResponse>)
    func get<OKResponse: Decodable,KOResponse: Decodable,T: Encodable>(url: String, params: T?, headers: [String:String]?, responseModel: OKResponse.Type, errorModel: KOResponse.Type, completion: @escaping CompletionHandler<OKResponse,KOResponse>)
    func get<OKResponse: Decodable,KOResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, errorModel: KOResponse.Type, completion: @escaping CompletionHandler<OKResponse,KOResponse>)
}

extension HTTPClient: HTTPClientGetProtocol {
    
    // MARK: - No JSON Parse
    public func get(url: String, params: [String : String]? = nil, headers: [String : String]? = nil, completion: @escaping CompletionHandler<Data,Data>) {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<T: Encodable>(url: String, params: T?, headers: [String : String]?, completion: @escaping CompletionHandler<Data, Data>) {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get(request: URLRequest, completion: @escaping CompletionHandler<Data,Data>) {
        _ = makeRequest(request: request, completion: completion)
    }
    
    // MARK: - JSON Parse OK Response
    
    public func get<OKResponse>(url: String, params: [String : String]? = nil, headers: [String : String]? = nil, responseModel: OKResponse.Type, completion: @escaping CompletionHandler<OKResponse, Data>) where OKResponse : Decodable {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, responseModel: responseModel, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<OKResponse: Decodable,T: Encodable>(url: String, params: T?, headers: [String : String]?, responseModel: OKResponse.Type, completion: @escaping CompletionHandler<OKResponse, Data>) {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, responseModel: responseModel, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<OKResponse>(request: URLRequest, responseModel: OKResponse.Type, completion: @escaping CompletionHandler<OKResponse, Data>) where OKResponse : Decodable {
        _ = makeRequest(request: request, completion: { result in
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
    
    public func get<OKResponse, KOResponse>(url: String, params: [String : String]? = nil, headers: [String : String]? = nil, responseModel: OKResponse.Type, errorModel: KOResponse.Type, completion: @escaping CompletionHandler<OKResponse, KOResponse>) where OKResponse : Decodable, KOResponse : Decodable {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, responseModel: responseModel, errorModel: errorModel, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<OKResponse: Decodable, KOResponse: Decodable, T: Encodable>(url: String, params: T?, headers: [String : String]?, responseModel: OKResponse.Type, errorModel: KOResponse.Type, completion: @escaping CompletionHandler<OKResponse, KOResponse>) {
        if let request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
            get(request: request, responseModel: responseModel, errorModel: errorModel, completion: completion)
        } else {
            self.callCompletionHandlerInMainThread(result: .failure(nil, .createRequest, 0, ""), completion: completion)
        }
    }
    
    public func get<OKResponse, KOResponse>(request: URLRequest, responseModel: OKResponse.Type, errorModel: KOResponse.Type, completion: @escaping CompletionHandler<OKResponse, KOResponse>) where OKResponse : Decodable, KOResponse : Decodable {
        _ = makeRequest(request: request, completion: { result in
            switch result {
            case let .success(data):
                self.handleDataTaskResponse(data: data, completion: completion)
            case let .failure(data, error, status, body):
                self.handleDataTaskError(data: data, httpError: error, status: status, body: body, completion: completion)
            default: break
            }
        })
    }
    
    // MARK: Handle response
    
    internal func handleDataTaskError<T>(data: Data?, httpError: HTTPError, status: Int, body: String?, completion: @escaping CompletionHandler<T,Data>) {
        self.callCompletionHandlerInMainThread(result: .failure(data, httpError, status, body), completion: completion)
    }
    
    internal func handleDataTaskError<T, E: Decodable>(data: Data?, httpError: HTTPError, status: Int, body: String?, completion: @escaping CompletionHandler<T,E>) {
        // Decode json
        if let data = data, let decodedResponse = try? JSONDecoder().decode(E.self, from: data) {
            self.callCompletionHandlerInMainThread(result: .failure(decodedResponse, httpError, status, body), completion: completion)
            return
        }
        
        var body = ""
        if let data = data {
            body = String(decoding: data, as: UTF8.self)
        }
        
        self.callCompletionHandlerInMainThread(result: .failure(nil, httpError, 0, body), completion: completion)
    }
    
    internal func handleDataTaskResponse<T: Decodable,E>(data: Data?, completion: @escaping CompletionHandler<T,E>) {
        // Decode json
        if let data = data {
            if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
                self.callCompletionHandlerInMainThread(result: .success(decodedResponse), completion: completion)
                return
            } else {
                let body = String(decoding: data, as: UTF8.self)
                self.callCompletionHandlerInMainThread(result: .failure(nil, .JSONParseError, 0, body), completion: completion)
                return
            }
        } else {
            self.callCompletionHandlerInMainThread(result: .success(nil), completion: completion)
        }
    }
}
