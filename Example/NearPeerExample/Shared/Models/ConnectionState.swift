//
//  ConnectionState.swift
//  NearPeerExample
//
//  Created by Assistant on 2024.
//

import Foundation

/// 接続状態を表すenum
enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    var displayText: String {
        switch self {
        case .disconnected:
            return "未接続"
        case .connecting:
            return "接続中..."
        case .connected:
            return "接続済み"
        case .error(let message):
            return "エラー: \(message)"
        }
    }
    
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    var isConnecting: Bool {
        if case .connecting = self {
            return true
        }
        return false
    }
}

/// メッセージデータモデル
struct MessageData: Codable, Identifiable, Equatable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let senderName: String
    let messageNumber: Int
    
    init(content: String, senderName: String, messageNumber: Int) {
        self.content = content
        self.senderName = senderName
        self.messageNumber = messageNumber
        self.timestamp = Date()
    }
}

/// ピア情報
struct PeerInfo: Identifiable, Equatable {
    let id: String
    let displayName: String
    
    init(displayName: String) {
        self.id = displayName
        self.displayName = displayName
    }
} 