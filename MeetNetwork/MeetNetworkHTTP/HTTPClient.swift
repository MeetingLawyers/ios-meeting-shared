//
//  MeetNetworkHTTPClient.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 16/8/21.
//

import Foundation

public typealias CompletionHandler<T,E> = (HTTPResult<T,E>?) -> Void

public protocol HTTPClientProtocol: HTTPClientGetProtocol, HTTPClientPostProtocol {
    func config(timeout: Double?)
    func setPinning(pinning: [String: String]?)
}

public class HTTPClient: NSObject, HTTPClientProtocol {
    
    public static let shared = HTTPClient()
    
    internal var session: URLSession?
    internal var requestTimeout: Double?
    internal var pinning: [String: String]?
    
    public func config(timeout: Double?) {
        self.requestTimeout = timeout
        self.session = nil
    }
    
    public func setPinning(pinning: [String: String]?) {
        self.pinning = pinning
    }
}
