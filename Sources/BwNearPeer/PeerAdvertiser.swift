//
//  PeerAdvertiser.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity
import Foundation

/// PeerAdvertiser
class PeerAdvertiser: NSObject, MCNearbyServiceAdvertiserDelegate {
    private let session: MCSession
    private var isAdvertising: Bool = false
    private var serviceType: String?
    private var infoArray: [String: String]?
    
    // より安全で効率的なDispatchQueue
    private let operationQueue = DispatchQueue(
        label: "com.beowulf-tech.bwtools.BwNearPeer.advertiser",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    // Continuation for async operations
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
                    logger.debug("PeerAdvertiser: selfがnil")
                    continuation.resume(throwing: NearPeerError.sessionNotFound)
                    return
                }
                
                guard !self.isAdvertising else {
                    logger.debug("PeerAdvertiser: すでにアドバタイズ中")
                    continuation.resume(returning: ())
                    return
                }

                logger.debug("PeerAdvertiser開始: serviceType=\(serviceType)")
                
                self.startContinuation = continuation
                self.isAdvertising = true
                self.serviceType = serviceType

                if let infos = discoveryInfo {
                    logger.debug("discoveryInfo設定: \(infos)")
                    self.infoArray = [String: String]()
                    infos.forEach { key, value in
                        self.infoArray?[key.rawValue] = value
                    }
                }

                logger.debug("MCNearbyServiceAdvertiser作成中...")
                self.advertiser = MCNearbyServiceAdvertiser(
                    peer: self.session.myPeerID,
                    discoveryInfo: self.infoArray,
                    serviceType: serviceType
                )
                self.advertiser?.delegate = self
                
                logger.debug("startAdvertisingPeer()呼び出し...")
                self.advertiser?.startAdvertisingPeer()
                
                // タイムアウトを設定
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    if let continuation = self?.startContinuation {
                        logger.debug("PeerAdvertiser開始完了（タイムアウト）")
                        continuation.resume(returning: ())
                        self?.startContinuation = nil
                    }
                }
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
        // より安全な招待処理
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
    
    /// アドバタイズでエラーが発生した場合の処理
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


