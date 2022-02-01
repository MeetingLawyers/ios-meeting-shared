//
//  HTTPResult.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 18/8/21.
//

import Foundation

public enum HTTPResult<T, U> {
    case success(T?, URLResponse?)
    case failure(U?, HTTPError, Int, String?)
}
