//
//  HTTPUtils.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 17/8/21.
//

import Foundation

class HTTPUtils {
    
    static func getLogName() -> String {
        return Bundle.init(for: HTTPUtils.self).infoDictionary?[kCFBundleNameKey as String] as? String ?? "MeetNetworkHTTP"
    }
}
