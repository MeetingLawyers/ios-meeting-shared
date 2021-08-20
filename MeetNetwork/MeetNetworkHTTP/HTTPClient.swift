//
//  MeetNetworkHTTPClient.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 16/8/21.
//

import Foundation

public typealias CompletionHandler<T,E> = (HTTPResult<T,E>?) -> Void

public protocol HTTPClientProtocol {
    // No JSON Parse
    func get(url: String, params: [String: String]?, headers: [String:String]?, completion: @escaping CompletionHandler<Data,Data>)
    func get(request: URLRequest, completion: @escaping CompletionHandler<Data,Data>)
    // JSON Parse OK Response
    func get<OKResponse: Decodable>(url: String, params: [String: String]?, headers: [String:String]?, responseModel: OKResponse.Type, completion: @escaping CompletionHandler<OKResponse,Data>)
    func get<OKResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, completion: @escaping CompletionHandler<OKResponse,Data>)
    // JSON Parse OK and KO Responses
    func get<OKResponse: Decodable,KOResponse: Decodable>(url: String, params: [String: String]?, headers: [String:String]?, responseModel: OKResponse.Type, errorModel: KOResponse.Type, completion: @escaping CompletionHandler<OKResponse,KOResponse>)
    func get<OKResponse: Decodable,KOResponse: Decodable>(request: URLRequest, responseModel: OKResponse.Type, errorModel: KOResponse.Type, completion: @escaping CompletionHandler<OKResponse,KOResponse>)
}

internal protocol HTTPClientUtilsProtocol {
    func createURLRequest(url: String, method: HTTPMethod, headers: [String: String]?, parameters: [String: String]?) -> URLRequest?
    func callCompletionHandlerInMainThread<T,E>(result: HTTPResult<T,E>, completion: @escaping CompletionHandler<T,E>)
}

public class HTTPClient {
    
    public static let shared = HTTPClient()
    
    private init() {
        
    }
    
    internal func getSession() -> URLSession {
        return URLSession.shared
    }
}

extension HTTPClient: HTTPClientProtocol {
    
    // MARK: - No JSON Parse
    public func get(url: String, params: [String : String]? = nil, headers: [String : String]? = nil, completion: @escaping CompletionHandler<Data,Data>) {
        if var request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
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
        if var request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
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
        if var request = createURLRequest(url: url, method: .get, headers: headers, parameters: params) {
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
    
    // MARK: - Internal Methods
    // MARK: Request
    
    internal func makeRequest(request: URLRequest, completion: @escaping CompletionHandler<Data,Data>) -> URLSessionDataTask {
        let session = getSession()
        print("\(HTTPUtils.getLogName()): makeRequest - \(request.httpMethod ?? "?") - \(request.url?.absoluteString ?? "?")")
        
        let dataTask = session.dataTask(with: request) { [weak self] data, urlResponse, error in
            var body = ""
            if let data = data {
                body = String(decoding: data, as: UTF8.self)
                print("\(HTTPUtils.getLogName()): response - \(body)")
            }
            let status = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
            
            if let error = error {
                self?.callCompletionHandlerInMainThread(result: .failure(data, .clientError, status, body), completion: completion)
            } else {
                guard let httpResponse = urlResponse as? HTTPURLResponse,
                      httpResponse.status?.responseType == .success else {
                    // Server error
                    self?.callCompletionHandlerInMainThread(result: .failure(data, .serverError, status, body), completion: completion)
                    return
                }
                
                self?.callCompletionHandlerInMainThread(result: .success(data), completion: completion)
            }
        }
        
        dataTask.resume()
        return dataTask
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

extension HTTPClient: HTTPClientUtilsProtocol {
    internal func createURLRequest(url: String, method: HTTPMethod, headers: [String: String]?, parameters: [String: String]?) -> URLRequest? {
        if let url = URL(string: url) {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            if let headers = headers {
                addRequestHeaders(request: &request, headers: headers)
            }
            if let params = parameters {
                addGetParameters(request: &request, parameters: params)
            }
            
            return request
        }
        
        return nil
    }
    
    internal func addRequestHeaders(request: inout URLRequest, headers: [String: String]) {
        for (header, value) in headers {
            request.addValue(value, forHTTPHeaderField: header)
        }
    }
    
    internal func addGetParameters(request: inout URLRequest, parameters: [String: String]) {
        if let stringURL = request.url?.absoluteString,
           var url = URLComponents(string: stringURL) {
            
            var queryItems = [URLQueryItem]()

            for (param, value) in parameters {
                queryItems.append(URLQueryItem(name: param, value: value))
            }
            
            url.queryItems = queryItems

            url.percentEncodedQuery = url.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            
            request.url = url.url
        }
    }
    
    internal func callCompletionHandlerInMainThread<T,E>(result: HTTPResult<T,E>, completion: @escaping CompletionHandler<T,E>) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}