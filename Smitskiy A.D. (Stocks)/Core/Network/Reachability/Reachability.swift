//
//  Reachability.swift
//  Smitskiy A.D. (Stocks)
//
//  Created by Алексей Смицкий on 29.08.2020.
//  Copyright © 2020 Смицкий А.Д. All rights reserved.
//

import UIKit
import SystemConfiguration

// MARK: - Reachability

final class Reachability: IReachability {
    
    // MARK: - Public methods
    
    var isConnectedToNetwork: Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                zeroSockAddress in SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)}
        }) else {
            return false
        }
        var flags : SCNetworkReachabilityFlags = []
        
        guard SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) else { return false }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
}
