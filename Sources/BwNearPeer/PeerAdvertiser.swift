//
//  PeerAdvertiser.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity
import Foundation

/// iOS17.6対応のPeerAdvertiser
class PeerAdvertiser: NSObject, MCNearbyServiceAdvertiserDelegate {
    private let session: MCSession
    private var isAdvertising: Bool = false
    private var serviceType: String?
    private var infoArray: [String: String]?
    
    // iOS17.6対応: より安全で効率的なDispatchQueue
    private let operationQueue = DispatchQueue(
        label: "com.beowulf-tech.bwtools.BwNearPeer.advertiser",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    // iOS17.6対応: Continuation for async operations
    private var startContinuation: CheckedContinuation<Void, Error>?
    private var stopContinuation: CheckedContinuation<Void, Never>?

    init(session: MCSession) {
        self.session = session
        super.init()
    }

    private var advertiser: MCNearbyServiceAdvertiser?

    /// 非同期でアドバタイズを開始
    func start(serviceType: String, discoveryInfo: [NearPeerDiscoveryInfoKey: String]? = nil) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            operationQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NearPeerError.sessionNotFound)
                    return
                }
                
                guard !self.isAdvertising else {
                    continuation.resume(returning: ())
                    return
                }

                self.startContinuation = continuation
                self.isAdvertising = true
                self.serviceType = serviceType

                if let infos = discoveryInfo {
                    self.infoArray = [String: String]()
                    infos.forEach { key, value in
                        self.infoArray?[key.rawValue] = value
                    }
                }

                self.advertiser = MCNearbyServiceAdvertiser(
                    peer: self.session.myPeerID,
                    discoveryInfo: self.infoArray,
                    serviceType: serviceType
                )
                self.advertiser?.delegate = self
                self.advertiser?.startAdvertisingPeer()
            }
        }
    }

    /// 非同期でアドバタイズを停止
    func stop() async {
        await withCheckedContinuation { continuation in
            operationQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                guard self.isAdvertising else {
                    continuation.resume()
                    return
                }

                self.stopContinuation = continuation
                self._stopAdvertising()
            }
        }
    }
    
    /// 内部的な停止処理
    private func _stopAdvertising() {
        advertiser?.delegate = nil
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isAdvertising = false
        
        stopContinuation?.resume()
        stopContinuation = nil
    }

    /// アドバタイズを再開
    func resume() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            operationQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NearPeerError.sessionNotFound)
                    return
                }
                
                guard !self.isAdvertising else {
                    continuation.resume(returning: ())
                    return
                }
                
                guard self.advertiser != nil else {
                    continuation.resume(throwing: NearPeerError.sessionNotFound)
                    return
                }

                self.startContinuation = continuation
                self.isAdvertising = true
                self.advertiser?.delegate = self
                self.advertiser?.startAdvertisingPeer()
            }
        }
    }

    /// アドバタイズを一時停止
    func suspend() async {
        await withCheckedContinuation { continuation in
            operationQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                guard self.isAdvertising else {
                    continuation.resume()
                    return
                }

                self.advertiser?.delegate = nil
                self.advertiser?.stopAdvertisingPeer()
                self.isAdvertising = false
                
                continuation.resume()
            }
        }
    }

    // MARK: - MCNearbyServiceAdvertiserDelegate

    /// セッションへの招待を受ける
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // iOS17.6対応: より安全な招待処理
        operationQueue.async { [weak self] in
            guard let self = self else {
                invitationHandler(false, nil)
                return
            }
            
            // 基本的なセキュリティチェック
            guard self.session.connectedPeers.count < 8 else { // 最大接続数制限
                invitationHandler(false, nil)
                return
            }
            
            invitationHandler(true, self.session)
        }
    }
    
    /// アドバタイズ開始に成功した場合の処理（iOS17.6では呼ばれないが、互換性のため保持）
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.isAdvertising = false
            
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
extension PeerAdvertiser {
    /// iOS17.6で利用可能な拡張機能
    
    /// アドバタイズの状態情報
    var advertisingStatus: [String: Any] {
        return [
            "isAdvertising": isAdvertising,
            "serviceType": serviceType ?? "未設定",
            "discoveryInfo": infoArray ?? [:],
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    /// アドバタイズ統計情報
    var statistics: [String: Any] {
        return [
            "peerID": session.myPeerID.displayName,
            "isAdvertising": isAdvertising,
            "connectedPeersCount": session.connectedPeers.count
        ]
    }
}
