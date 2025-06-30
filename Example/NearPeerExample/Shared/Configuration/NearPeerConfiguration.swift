//
//  NearPeerConfiguration.swift
//  NearPeerExample
//
//  Created by Assistant on 2024.
//

import Foundation
import BwNearPeer
import UIKit

/// NearPeer設定を管理するクラス
struct NearPeerConfiguration {
    static let shared = NearPeerConfiguration()
    
    // MARK: - Constants
    let serviceType = "nearpeer"
    let maxPeers = 1
    
    let discoveryInfo: [NearPeerDiscoveryInfoKey: String] = [
        .identifier: "com.beowulf-tech.sirudoor.discovery.name",
        .passcode: "4989"
    ]
    
    var displayName: String {
        UIDevice.current.name
    }
    
    // MARK: - Message Configuration
    let messagePrefix = "回目"
    
    private init() {}
    
    // MARK: - Helper Methods
    func formatMessage(content: String, number: Int) -> String {
        return "\(number)\(messagePrefix) \(content)"
    }
}

/// ログレベル設定
enum LogLevel {
    case debug
    case info
    case warning
    case error
    
    var prefix: String {
        switch self {
        case .debug: return "[DEBUG]"
        case .info: return "[INFO]"
        case .warning: return "[WARNING]"
        case .error: return "[ERROR]"
        }
    }
} 