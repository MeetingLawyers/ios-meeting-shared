//
//  HTTPError.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 18/8/21.
//

import Foundation

public enum HTTPError: Error {
    // Server Error
    case serverError
    // Client Error
    case clientError
    case noInternet
    case timeout
    // Other
    case JSONParseError
    case responseModelNotConformsDecodable
    case createRequest
    case unknownError
}
