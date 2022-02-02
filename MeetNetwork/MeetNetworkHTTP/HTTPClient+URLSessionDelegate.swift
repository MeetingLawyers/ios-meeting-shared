//
//  HTTPClient+URLSessionDelegate.swift
//  MeetNetworkHTTP
//
//  Created by Manel MeetingLawyers on 15/12/21.
//

import Foundation
import CommonCrypto

// MARK: URLSessionDelegate - PINNING
extension HTTPClient: URLSessionDelegate {
    
    internal var rsa2048Asn1Header:[UInt8] {
        get { return [
            0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
            0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
        ] }
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard   let serverTrust = challenge.protectionSpace.serverTrust,
                let pinning = self.pinning,
                let pinningRecordKey = pinning.keys.first(where: { challenge.protectionSpace.host.contains($0) }),
                let pinningHash = pinning[pinningRecordKey]
        else {
            print("\(HTTPUtils.getLogName()): didReceive challenge - NO PINNING HOST MATCH")
            completionHandler(.performDefaultHandling, nil);
            return;
        }

        // Set SSL policies for domain name check
        let policies = NSMutableArray();
        policies.add(SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString)));
        SecTrustSetPolicies(serverTrust, policies);
        
        if SecTrustEvaluateWithError(serverTrust, nil) {
            let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
            //Compare public key
            let policy = SecPolicyCreateBasicX509();
            let cfCertificates = [certificate] as CFArray;

            var trust: SecTrust?
            SecTrustCreateWithCertificates(cfCertificates, policy, &trust);

            var pubKey: SecKey?
            
            if #available(iOS 14, *) {
                if let trust = trust {
                    pubKey = SecTrustCopyKey(trust)
                }
            } else {
                if let trust = trust {
                    pubKey = SecTrustCopyPublicKey(trust)
                }
            }
            
            if let pubKey = pubKey {
                var error:Unmanaged<CFError>?
                if let pubKeyData = SecKeyCopyExternalRepresentation(pubKey, &error) {
                    let sha256Key = sha256(data: pubKeyData as Data);
                    if(pinningHash.contains(sha256Key)) {
                        print("\(HTTPUtils.getLogName()): didReceive challenge - PINNING OK")
                        let credential = URLCredential(trust: serverTrust);
                        completionHandler(.useCredential, credential);
                        return
                    }
                }
            }
        }
        
        print("\(HTTPUtils.getLogName()): didReceive challenge - PINNING ERROR")
        completionHandler(.cancelAuthenticationChallenge, nil);
    }
    
    private func sha256(data : Data) -> String {
        var keyWithHeader = Data(rsa2048Asn1Header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        keyWithHeader.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(keyWithHeader.count), &hash)
        }
        
        return Data(hash).base64EncodedString()
    }
}

// MARK: URLSessionDelegate - METRICS

extension HTTPClient: URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        let duration = metrics.taskInterval.duration
        print("\(HTTPUtils.getLogName()): RESPONSE - \(task.originalRequest?.httpMethod ?? "?") (\(round(1000 * duration)) ms) - \(task.originalRequest?.url?.absoluteString ?? "?")")
        for metric in metrics.transactionMetrics {
            var status = 0
            if let httpResponse = metric.response as? HTTPURLResponse {
                status = httpResponse.statusCode
            }
            
            print("\(HTTPUtils.getLogName()): TRANSACTION - \(metric.request.httpMethod ?? "?") - status \(status) - \(getFetchType(type: metric.resourceFetchType)) - \(metric.countOfResponseBodyBytesReceived) Bytes - \(metric.request.url?.absoluteString ?? "?")")
        }
        print(task)
    }
    
    internal func getFetchType(type: URLSessionTaskMetrics.ResourceFetchType) -> String {
        switch type {
        case .localCache:
            return "LOCAL"
        case .networkLoad:
            return "NETWORK"
        default:
            return "?"
        }
    }
}
