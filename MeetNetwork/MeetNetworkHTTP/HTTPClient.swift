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
    
    /// Set HOST : SHA256 key. Example ["google.com" : "Z7iX8iPL/tb+En3S+O8dX8VWg/fn/BYJGWopTO3cNqU="]
    /// - Parameter pinning: key value pinning
    public func setPinning(pinning: [String: String]?) {
        if let pinning = pinning {
            let pinningSanitized = Dictionary(uniqueKeysWithValues: pinning.map { key, value in (key.replacingOccurrences(of: "*.", with: ""), value) })
            self.pinning = pinningSanitized
            return
        }
        self.pinning = nil
    }
}
