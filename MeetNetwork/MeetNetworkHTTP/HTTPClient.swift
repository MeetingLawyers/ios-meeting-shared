//
//  MeetNetworkHTTPClient.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 16/8/21.
//

import Foundation

public typealias RequestCompletionHandler<T,E> = (HTTPResult<T,E>?) -> Void

public protocol HTTPClientProtocol: HTTPClientGetProtocol, HTTPClientPostProtocol {
    func config(timeout: Double?)
    func config(cache: URLCache?)
    func config(pinning: [String: String]?)
    func clearAllCache()
}

public class HTTPClient: NSObject, HTTPClientProtocol {
    
    public typealias Output = (data: Data, response: URLResponse)
    public typealias DecodedOutput<T> = (data: T, response: URLResponse)
    
    public static let shared = HTTPClient()
    
    internal var session: URLSession?
    internal var requestTimeout: Double?
    internal var cache: URLCache?
    internal var pinning: [String: String]?
    
    override public init() {
        
    }
    
    public init(cache: URLCache?, timeout: Double?, pinning: [String: String]?) {
        super.init()
        self.config(cache: cache)
        self.config(timeout: timeout)
        self.config(pinning: pinning)
    }
    
    public func config(timeout: Double?) {
        self.requestTimeout = timeout
        self.session = nil
    }
    
    public func config(cache: URLCache?) {
        self.cache = cache
        self.session = nil
    }
    
    /// Set HOST : SHA256 key. Example ["google.com" : "Z7iX8iPL/tb+En3S+O8dX8VWg/fn/BYJGWopTO3cNqU="]
    /// - Parameter pinning: key value pinning
    public func config(pinning: [String: String]?) {
        if let pinning = pinning {
            let pinningSanitized = Dictionary(uniqueKeysWithValues: pinning.map { key, value in (key.replacingOccurrences(of: "*.", with: ""), value) })
            self.pinning = pinningSanitized
            return
        }
        self.pinning = nil
    }
    
    public func clearAllCache() {
        self.session?.configuration.urlCache?.removeAllCachedResponses()
    }
}
