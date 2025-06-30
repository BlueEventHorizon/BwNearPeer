//
//  NearPeer.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity
import Foundation

// MARK: - Error Types

/// NearPeerで発生する可能性のあるエラー
public enum NearPeerError: Error, LocalizedError {
    case invalidServiceType(String)
    case invalidDisplayName(String)
    case sessionNotFound
    case peerNotConnected
    case encodingFailed
    case sendingFailed(Error)
    case startupFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidServiceType(let serviceType):
            return "無効なサービスタイプです: \(serviceType)"
        case .invalidDisplayName(let displayName):
            return "無効な表示名です: \(displayName)"
        case .sessionNotFound:
            return "セッションが見つかりません"
        case .peerNotConnected:
            return "ピアが接続されていません"
        case .encodingFailed:
            return "データのエンコードに失敗しました"
        case .sendingFailed(let error):
            return "データの送信に失敗しました: \(error.localizedDescription)"
        case .startupFailed(let error):
            return "サービスの開始に失敗しました: \(error.localizedDescription)"
        }
    }
}

// MARK: - Discovery Info

/// 文字列を使用するために、ここでenum定義をしておく
public enum NearPeerDiscoveryInfoKey: String, CaseIterable {
    /// Bundle Identifierなどアプリを特定するために使用すると良い
    case identifier

    /// ４桁の数字など、事前に交換した簡易な数字を与えると良い
    case passcode
}

// MARK: - Event Types

/// ピア接続に関するイベント
public struct PeerConnectionEvent {
    public let peerID: MCPeerID
    public let state: MCSessionState
    public let timestamp: Date
    
    public init(peerID: MCPeerID, state: MCSessionState) {
        self.peerID = peerID
        self.state = state
        self.timestamp = Date()
    }
}

/// データ受信イベント
public struct DataReceivedEvent {
    public let peerID: MCPeerID
    public let data: Data
    public let timestamp: Date
    
    public init(peerID: MCPeerID, data: Data) {
        self.peerID = peerID
        self.data = data
        self.timestamp = Date()
    }
}

// MARK: - Protocol

/// Swift Concurrency対応のNearPeerプロトコル
public protocol NearPeerProtocol: Actor {
    init(maxPeers: Int)
    
    func start(
        serviceType: String,
        displayName: String,
        myDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]?,
        targetDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]?
    ) async throws
    
    func stop() async
    func resume() async throws
    func suspend() async
    
    func send(_ data: Data) async throws
    func send<T: Codable>(_ object: T) async throws
    
    var connectionEvents: AsyncStream<PeerConnectionEvent> { get }
    var dataReceivedEvents: AsyncStream<DataReceivedEvent> { get }
    var connectedPeers: [MCPeerID] { get async }
}



// MARK: - NearPeer Actor

/// NearPeerクラス（Actor対応）
@available(iOS 17.0, macOS 14.0, *)
public actor NearPeer: NearPeerProtocol {
    private let maxNumPeers: Int
    private var connection: PeerConnection?
    private var advertiser: PeerAdvertiser?
    private var browser: PeerBrowser?
    
    // AsyncStreamの継続用
    private var connectionEventContinuation: AsyncStream<PeerConnectionEvent>.Continuation?
    private var dataEventContinuation: AsyncStream<DataReceivedEvent>.Continuation?
    
    // Public AsyncStreams
    public let connectionEvents: AsyncStream<PeerConnectionEvent>
    public let dataReceivedEvents: AsyncStream<DataReceivedEvent>
    
    // MARK: - Initialization
    
    public init(maxPeers: Int) {
        self.maxNumPeers = maxPeers
        
        // AsyncStreamの初期化
        (self.connectionEvents, self.connectionEventContinuation) = AsyncStream<PeerConnectionEvent>.makeStream()
        (self.dataReceivedEvents, self.dataEventContinuation) = AsyncStream<DataReceivedEvent>.makeStream()
    }
    
    deinit {
        connectionEventContinuation?.finish()
        dataEventContinuation?.finish()
    }
    
    // MARK: - Validation
    
    private func validateServiceType(_ serviceType: String) throws -> String {
        guard !serviceType.isEmpty else {
            throw NearPeerError.invalidServiceType("サービスタイプが空です")
        }
        
        guard serviceType.count <= 15 else {
            throw NearPeerError.invalidServiceType("サービスタイプは15文字以下である必要があります")
        }
        
        // 基本的な文字チェック
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        guard serviceType.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            throw NearPeerError.invalidServiceType("サービスタイプには英数字とハイフンのみ使用できます")
        }
        
        return serviceType
    }
    
    private func validateDisplayName(_ displayName: String) throws -> String {
        guard !displayName.isEmpty else {
            throw NearPeerError.invalidDisplayName("表示名が空です")
        }
        
        let maxBytes = 63
        guard displayName.utf8.count <= maxBytes else {
            throw NearPeerError.invalidDisplayName("表示名は63バイト以下である必要があります")
        }
        
        return displayName
    }
    
    // MARK: - Public Methods
    
    public func start(
        serviceType: String,
        displayName: String,
        myDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? = nil,
        targetDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? = nil
    ) async throws {
        logger.debug("🟢 NearPeer.start() 開始")
        logger.debug("入力 - serviceType: \(serviceType), displayName: \(displayName)")
        
        let validatedServiceType = try validateServiceType(serviceType)
        let validatedDisplayName = try validateDisplayName(displayName)
        
        logger.debug("バリデーション完了 - serviceType: \(validatedServiceType), displayName: \(validatedDisplayName)")
        
        // 既存の接続を停止
        logger.debug("既存接続の停止中...")
        await stop()
        logger.debug("🟢 既存接続停止完了")
        
        do {
            // 新しい接続を作成
            logger.debug("新しい接続を作成中...")
            self.connection = PeerConnection(displayName: validatedDisplayName)
            
            guard let connection = self.connection else {
                logger.debug("接続の作成に失敗")
                throw NearPeerError.sessionNotFound
            }
            logger.debug("🟢 接続作成完了")
            
            // イベントハンドラーを設定
            logger.debug("イベントハンドラーを設定中...")
            connection.setEventHandlers(
                connectionHandler: { [weak self] event in
                    Task { await self?.handleConnectionEvent(event) }
                },
                dataHandler: { [weak self] event in
                    Task { await self?.handleDataEvent(event) }
                }
            )
            logger.debug("🟢 イベントハンドラー設定完了")
            
            // AdvertiserとBrowserを作成
            logger.debug("AdvertiserとBrowserを作成中...")
            self.advertiser = PeerAdvertiser(session: connection.session)
            self.browser = PeerBrowser(session: connection.session, maxPeers: maxNumPeers)
            logger.debug("AdvertiserとBrowser作成完了")
            
            // サービスを開始
            if let myDiscoveryInfo = myDiscoveryInfo {
                logger.debug("Advertiser開始中... (discoveryInfo: \(myDiscoveryInfo))")
                try await advertiser?.start(serviceType: validatedServiceType, discoveryInfo: myDiscoveryInfo)
                logger.debug("🟢 Advertiser開始完了")
            } else {
                logger.debug("Advertiser開始をスキップ（discoveryInfoなし）")
            }
            
            if let targetDiscoveryInfo = targetDiscoveryInfo {
                logger.debug("Browser開始中... (targetDiscoveryInfo: \(targetDiscoveryInfo))")
                try await browser?.start(serviceType: validatedServiceType, discoveryInfo: targetDiscoveryInfo)
                logger.debug("🟢 Browser開始完了")
            } else {
                logger.debug("Browser開始をスキップ（targetDiscoveryInfoなし）")
            }
            
            logger.debug("🟢 NearPeer.start() 完了")
            
        } catch {
            logger.debug("NearPeer.start()でエラー: \(error)")
            throw NearPeerError.startupFailed(error)
        }
    }
    
    public func stop() async {
        await advertiser?.stop()
        await browser?.stop()
        connection?.disconnect()
        
        advertiser = nil
        browser = nil
        connection = nil
    }
    
    public func resume() async throws {
        try await advertiser?.resume()
        try await browser?.resume()
    }
    
    public func suspend() async {
        await advertiser?.suspend()
        await browser?.suspend()
        connection?.disconnect()
    }
    
    public func send(_ data: Data) async throws {
        guard let connection = self.connection else {
            throw NearPeerError.sessionNotFound
        }
        
        let peers = connection.session.connectedPeers
        
        guard !peers.isEmpty else {
            throw NearPeerError.peerNotConnected
        }
        
        do {
            try connection.session.send(data, toPeers: peers, with: .reliable)
        } catch {
            throw NearPeerError.sendingFailed(error)
        }
    }
    
    public func send<T: Codable>(_ object: T) async throws {
        do {
            let data = try JSONEncoder().encode(object)
            try await send(data)
        } catch is EncodingError {
            throw NearPeerError.encodingFailed
        }
    }
    
    public var connectedPeers: [MCPeerID] {
        get async {
            return connection?.session.connectedPeers ?? []
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleConnectionEvent(_ event: PeerConnectionEvent) {
        connectionEventContinuation?.yield(event)
    }
    
    private func handleDataEvent(_ event: DataReceivedEvent) {
        dataEventContinuation?.yield(event)
    }
}


