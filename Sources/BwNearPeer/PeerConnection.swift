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
    
    // DispatchQueueでスレッドセーフティを確保
    private let handlerQueue = DispatchQueue(label: "com.beowulf-tech.bwtools.BwNearPeer.connection", qos: .utility)
    
    init(displayName: String = "unknown") {
        self.peerID = MCPeerID(displayName: String(displayName.prefix(63)))
        
        // セキュリティを向上: 暗号化を必須に
        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
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
    
    func disconnect() {
        session.disconnect()
    }
    
    // MARK: - MCSessionDelegate
    
    /// 近くのPeerから NSData オブジェクトを受信したことを示す。必須。
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        handlerQueue.async { [weak self] in
            if let eventHandler = self?.dataEventHandler {
                let event = DataReceivedEvent(peerID: peerID, data: data)
                eventHandler(event)
            }
        }
    }
    
    /// ローカルPeerが近くのPeerからリソースの受信を開始したことを示す。必須。
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // 将来的にリソース転送イベントを追加する場合はここで実装
    }
    
    /// ローカルPeerが近くのPeerからリソースの受信を終了したことを示す。必須。
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // 将来的にリソース転送完了イベントを追加する場合はここで実装
    }
    
    /// 近くのピアからローカルピアへのバイトストリーム接続が開かれたときに呼び出されます。必須。
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // 将来的にストリーミングイベントを追加する場合はここで実装
    }
    
    /// 近くのピアの状態が変化したときに呼び出されます。必須。
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        self.state = state
        
        handlerQueue.async { [weak self] in
            if let eventHandler = self?.connectionEventHandler {
                let event = PeerConnectionEvent(peerID: peerID, state: state)
                eventHandler(event)
            }
        }
    }
    
    /// 接続が最初に確立されたときに、相手から提供されたクライアント証明書を検証するために呼び出されます。
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        // 現在はすべての証明書を受け入れるが、将来的にはより厳密な検証を実装可能
        certificateHandler(true)
    }
}

// MARK: - Enhanced Features

@available(iOS 17.0, macOS 14.0, *)
extension PeerConnection {
    /// 接続品質の情報を取得
    var connectionQuality: String {
        switch state {
        case .connected:
            return "接続済み"
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
