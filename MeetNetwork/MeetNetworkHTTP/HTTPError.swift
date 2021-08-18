//
//  HTTPError.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 18/8/21.
//

import Foundation

public enum HTTPError: Error {
    case JSONParseError
    case responseModelNotConformsDecodable
    case createRequest
    case serverError
    case clientError
    case unknownError
}
