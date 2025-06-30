//
//  PeerBrowser.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity
import Foundation

/// iOS17.6対応のPeerBrowser
class PeerBrowser: NSObject, MCNearbyServiceBrowserDelegate {
    private let session: MCSession
    private let maxNumPeers: Int
    private var browser: MCNearbyServiceBrowser?
    private var discoveryInfo: [NearPeerDiscoveryInfoKey: String]?
    private var isBrowsing: Bool = false
    private var serviceType: String?
    
    // iOS17.6対応: より安全で効率的なDispatchQueue
    private let operationQueue = DispatchQueue(
        label: "com.beowulf-tech.bwtools.BwNearPeer.browser",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    // iOS17.6対応: Continuation for async operations
    private var startContinuation: CheckedContinuation<Void, Error>?
    private var stopContinuation: CheckedContinuation<Void, Never>?
    
    // iOS17.6対応: 発見されたピアの履歴
    private var discoveredPeers: Set<MCPeerID> = []
    private let peersQueue = DispatchQueue(label: "com.beowulf-tech.bwtools.BwNearPeer.peers", attributes: .concurrent)

    init(session: MCSession, maxPeers: Int) {
        self.session = session
        self.maxNumPeers = maxPeers
        super.init()
    }

    /// 非同期でブラウジングを開始
    func start(serviceType: String, discoveryInfo: [NearPeerDiscoveryInfoKey: String]?) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            operationQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NearPeerError.sessionNotFound)
                    return
                }
                
                guard !self.isBrowsing else {
                    continuation.resume(returning: ())
                    return
                }

                self.startContinuation = continuation
                self.serviceType = serviceType
                self.browser = MCNearbyServiceBrowser(peer: self.session.myPeerID, serviceType: serviceType)
                self.browser?.delegate = self
                self.browser?.startBrowsingForPeers()
                self.discoveryInfo = discoveryInfo
                self.isBrowsing = true

                // 即座に成功を返す（ブラウジング開始は通常失敗しない）
                continuation.resume(returning: ())
                self.startContinuation = nil
            }
        }
    }

    /// 非同期でブラウジングを停止
    func stop() async {
        await withCheckedContinuation { continuation in
            operationQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                guard self.isBrowsing else {
                    continuation.resume()
                    return
                }

                self.stopContinuation = continuation
                self._stopBrowsing()
            }
        }
    }
    
    /// 内部的な停止処理
    private func _stopBrowsing() {
        browser?.delegate = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
        
        // 発見されたピアの履歴をクリア
        peersQueue.async(flags: .barrier) { [weak self] in
            self?.discoveredPeers.removeAll()
        }
        
        stopContinuation?.resume()
        stopContinuation = nil
    }

    /// ブラウジングを再開
    func resume() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            operationQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NearPeerError.sessionNotFound)
                    return
                }
                
                guard !self.isBrowsing else {
                    continuation.resume(returning: ())
                    return
                }
                
                guard self.browser != nil else {
                    continuation.resume(throwing: NearPeerError.sessionNotFound)
                    return
                }

                self.browser?.delegate = self
                self.browser?.startBrowsingForPeers()
                self.isBrowsing = true
                
                continuation.resume(returning: ())
            }
        }
    }

    /// ブラウジングを一時停止
    func suspend() async {
        await withCheckedContinuation { continuation in
            operationQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                guard self.isBrowsing else {
                    continuation.resume()
                    return
                }

                self.browser?.delegate = nil
                self.browser?.stopBrowsingForPeers()
                self.isBrowsing = false
                
                continuation.resume()
            }
        }
    }

    /// Discovery情報がマッチするかチェック
    private func isMatchDiscoveryInfo(_ info: [String: String]?) -> Bool {
        guard let discoveryInfo = discoveryInfo else {
            // discoveryInfoが定義されていない場合は、なんでも受け入れる
            return true
        }

        guard let info = info else {
            // discoveryInfoが定義されていて、ブラウズしたpeerがdiscoveryInfoを持っていない場合は、接続しない
            return false
        }

        for key in discoveryInfo.keys {
            if discoveryInfo[key] == info[key.rawValue] {
                continue
            } else {
                // ひとつでも一致しない場合は、接続しない
                return false
            }
        }

        return true
    }
    
    /// ピアを発見履歴に追加
    private func addDiscoveredPeer(_ peerID: MCPeerID) {
        peersQueue.async(flags: .barrier) { [weak self] in
            self?.discoveredPeers.insert(peerID)
        }
    }
    
    /// ピアを発見履歴から削除
    private func removeDiscoveredPeer(_ peerID: MCPeerID) {
        peersQueue.async(flags: .barrier) { [weak self] in
            self?.discoveredPeers.remove(peerID)
        }
    }

    // MARK: - MCNearbyServiceBrowserDelegate

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // iOS17.6対応: より厳密なピア発見処理
            guard self.isMatchDiscoveryInfo(info) else {
                return
            }
            
            // 最大接続数チェック
            guard self.session.connectedPeers.count < self.maxNumPeers else {
                return
            }
            
            // 既に接続済みのピアでないかチェック
            guard !self.session.connectedPeers.contains(peerID) else {
                return
            }
            
            self.addDiscoveredPeer(peerID)
            
            // iOS17.6では、より安全なタイムアウト設定
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        operationQueue.async { [weak self] in
            self?.removeDiscoveredPeer(peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.isBrowsing = false
            
            // エラーをContinuationに伝達
            if let continuation = self.startContinuation {
                continuation.resume(throwing: NearPeerError.startupFailed(error))
                self.startContinuation = nil
            }
        }
    }
}

// MARK: - iOS17.6 Enhanced Features

@available(iOS 17.0, macOS 14.0, *)
extension PeerBrowser {
    /// iOS17.6で利用可能な拡張機能
    
    /// ブラウジングの状態情報
    var browsingStatus: [String: Any] {
        return [
            "isBrowsing": isBrowsing,
            "serviceType": serviceType ?? "未設定",
            "maxPeers": maxNumPeers,
            "discoveryInfo": discoveryInfo?.mapValues { $0 } ?? [:],
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    /// ブラウジング統計情報
    var statistics: [String: Any] {
        return peersQueue.sync {
            return [
                "peerID": session.myPeerID.displayName,
                "isBrowsing": isBrowsing,
                "discoveredPeersCount": discoveredPeers.count,
                "connectedPeersCount": session.connectedPeers.count,
                "maxPeers": maxNumPeers
            ]
        }
    }
    
    /// 発見されたピアのリスト
    var discoveredPeersList: [MCPeerID] {
        return peersQueue.sync {
            return Array(discoveredPeers)
        }
    }
}