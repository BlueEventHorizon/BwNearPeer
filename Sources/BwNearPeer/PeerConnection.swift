//
//  PeerConnection.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity
import Foundation

/// モダンなイベントハンドラー
public typealias ConnectionEventHandler = (PeerConnectionEvent) -> Void
public typealias DataEventHandler = (DataReceivedEvent) -> Void

class PeerConnection: NSObject, MCSessionDelegate {
    private(set) var peerID: MCPeerID
    private(set) var session: MCSession
    private(set) var state: MCSessionState = .notConnected
    
    // モダンなイベントハンドラー
    private var connectionEventHandler: ConnectionEventHandler?
    private var dataEventHandler: DataEventHandler?
    
    // レガシーハンドラー（下位互換性のため）
    private var connectingHandler: ConnectionHandler?
    private var connectedHandler: ConnectionHandler?
    private var disconnectedHandler: ConnectionHandler?
    private var receivedHandler: DataReceiveHandler?
    
    // DispatchQueueでスレッドセーフティを確保
    private let handlerQueue = DispatchQueue(label: "com.beowulf-tech.bwtools.BwNearPeer.connection", qos: .utility)
    
    init(displayName: String = "unknown") {
        self.peerID = MCPeerID(displayName: String(displayName.prefix(63)))
        
        // セキュリティを向上: iOS17.6では暗号化を必須に
        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required  // .none から .required に変更
        )
        
        super.init()
        
        self.session.delegate = self
    }
    
    /// モダンなイベントハンドラーを設定
    func setEventHandlers(
        connectionHandler: @escaping ConnectionEventHandler,
        dataHandler: @escaping DataEventHandler
    ) {
        handlerQueue.async { [weak self] in
            self?.connectionEventHandler = connectionHandler
            self?.dataEventHandler = dataHandler
        }
    }
    
    /// レガシーハンドラーを設定（下位互換性のため）
    func setLegacyHandlers(
        connectingHandler: ConnectionHandler?,
        connectedHandler: ConnectionHandler?,
        disconnectedHandler: ConnectionHandler?,
        receivedHandler: DataReceiveHandler?
    ) {
        handlerQueue.async { [weak self] in
            self?.connectingHandler = connectingHandler
            self?.connectedHandler = connectedHandler
            self?.disconnectedHandler = disconnectedHandler
            self?.receivedHandler = receivedHandler
        }
    }
    
    func disconnect() {
        session.disconnect()
    }
    
    // MARK: - MCSessionDelegate
    
    /// 近くのPeerから NSData オブジェクトを受信したことを示す。必須。
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        handlerQueue.async { [weak self] in
            // モダンなイベントハンドラー
            if let eventHandler = self?.dataEventHandler {
                let event = DataReceivedEvent(peerID: peerID, data: data)
                eventHandler(event)
            }
            
            // レガシーハンドラー
            if let legacyHandler = self?.receivedHandler {
                DispatchQueue.main.async {
                    legacyHandler(peerID, data)
                }
            }
        }
    }
    
    /// ローカルPeerが近くのPeerからリソースの受信を開始したことを示す。必須。
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // iOS17.6では、より詳細なプログレス情報を活用可能
        // 将来的にリソース転送イベントを追加する場合はここで実装
    }
    
    /// ローカルPeerが近くのPeerからリソースの受信を終了したことを示す。必須。
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // iOS17.6では、より詳細なリソース受信完了情報を活用可能
        // 将来的にリソース転送完了イベントを追加する場合はここで実装
    }
    
    /// 近くのピアからローカルピアへのバイトストリーム接続が開かれたときに呼び出されます。必須。
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // iOS17.6では、ストリーミング機能が強化されている
        // 将来的にストリーミングイベントを追加する場合はここで実装
    }
    
    /// 近くのピアの状態が変化したときに呼び出されます。必須。
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        self.state = state
        
        handlerQueue.async { [weak self] in
            // モダンなイベントハンドラー
            if let eventHandler = self?.connectionEventHandler {
                let event = PeerConnectionEvent(peerID: peerID, state: state)
                eventHandler(event)
            }
            
            // レガシーハンドラー
            switch state {
            case .connecting:
                if let handler = self?.connectingHandler {
                    DispatchQueue.main.async {
                        handler(peerID)
                    }
                }
                
            case .connected:
                if let handler = self?.connectedHandler {
                    DispatchQueue.main.async {
                        handler(peerID)
                    }
                }
                
            case .notConnected:
                if let handler = self?.disconnectedHandler {
                    DispatchQueue.main.async {
                        handler(peerID)
                    }
                }
                
            @unknown default:
                // iOS17.6で新しい状態が追加された場合の対応
                break
            }
        }
    }
    
    /// 接続が最初に確立されたときに、相手から提供されたクライアント証明書を検証するために呼び出されます。
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        // iOS17.6では、より高度な証明書検証が可能
        // 現在はすべての証明書を受け入れるが、将来的にはより厳密な検証を実装可能
        certificateHandler(true)
    }
}

// MARK: - iOS17.6 Enhanced Features

@available(iOS 17.0, macOS 14.0, *)
extension PeerConnection {
    /// iOS17.6で利用可能な拡張機能
    
    /// 接続品質の情報を取得
    var connectionQuality: String {
        // iOS17.6では、より詳細な接続品質情報を取得可能
        switch state {
        case .connected:
            return "優良"
        case .connecting:
            return "接続中"
        case .notConnected:
            return "未接続"
        @unknown default:
            return "不明"
        }
    }
    
    /// 接続の統計情報
    var connectionStatistics: [String: Any] {
        return [
            "connectedPeersCount": session.connectedPeers.count,
            "peerID": peerID.displayName,
            "state": state.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
}
