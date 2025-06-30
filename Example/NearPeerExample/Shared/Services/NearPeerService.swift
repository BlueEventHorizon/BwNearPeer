//
//  NearPeerService.swift
//  NearPeerExample
//
//  Created by Assistant on 2024.
//

import Foundation
import BwNearPeer
import SwiftUI

/// NearPeerサービス
@Observable
final class NearPeerService {
    // MARK: - Properties
    private let nearPeer: NearPeer
    private let configuration = NearPeerConfiguration.shared
    private var messageCounter = 0
    private var monitoringTask: Task<Void, Never>?
    
    // MARK: - Published State
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var connectedPeers: [PeerInfo] = []
    private(set) var lastReceivedMessage: MessageData?
    private(set) var lastError: String = ""
    
    // MARK: - Computed Properties
    var isConnected: Bool {
        connectionState.isConnected
    }
    
    var connectionStatusText: String {
        connectionState.displayText
    }
    
    var peersDisplayText: String {
        if connectedPeers.isEmpty {
            return "なし"
        }
        return connectedPeers.map(\.displayName).joined(separator: ", ")
    }
    
    // MARK: - Initialization
    init() {
        self.nearPeer = NearPeer(maxPeers: configuration.maxPeers)
        startService()
    }
    
    deinit {
        monitoringTask?.cancel()
        Task { [nearPeer] in
            await nearPeer.stop()
        }
    }
    
    // MARK: - Public Methods
    func sendMessage(_ content: String) async throws {
        guard isConnected else {
            throw NearPeerServiceError.notConnected
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NearPeerServiceError.emptyMessage
        }
        
        let formattedMessage = configuration.formatMessage(content: content, number: messageCounter)
        
        print("メッセージ送信開始: \(formattedMessage)")
        
        do {
            // CodableのStringとして送信（JSONエンコードされる）
            try await nearPeer.send(formattedMessage)
            print("🔵 メッセージ送信完了")
            
            await MainActor.run {
                messageCounter += 1
                clearError()
            }
        } catch {
            print("メッセージ送信エラー: \(error.localizedDescription)")
            await MainActor.run {
                setError("送信エラー: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    func reconnect() async throws {
        do {
            try await nearPeer.resume()
            await MainActor.run {
                clearError()
            }
        } catch {
            await MainActor.run {
                setError("再接続エラー: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    func disconnect() async {
        await nearPeer.suspend()
        await MainActor.run {
            connectionState = .disconnected
        }
    }
    
    func clearError() {
        lastError = ""
    }
    
    // MARK: - Private Methods
    private func startService() {
        monitoringTask = Task { [weak self] in
            guard let self else { return }
            
            await withTaskGroup(of: Void.self) { group in
                // イベント監視タスクを追加
                group.addTask { [weak self] in
                    await self?.monitorConnectionEvents()
                }
                
                group.addTask { [weak self] in
                    await self?.monitorDataEvents()
                }
                
                // サービス開始タスクを追加
                group.addTask { [weak self] in
                    await self?.initializeNearPeer()
                }
            }
        }
    }
    
    private func initializeNearPeer() async {
        do {
            print("NearPeer初期化開始")
            print("サービスタイプ: \(configuration.serviceType)")
            print("表示名: \(configuration.displayName)")
            print("発見情報: \(configuration.discoveryInfo)")
            
            print("nearPeer.start()呼び出し中...")
            
            try await nearPeer.start(
                serviceType: configuration.serviceType,
                displayName: configuration.displayName,
                myDiscoveryInfo: configuration.discoveryInfo,
                targetDiscoveryInfo: configuration.discoveryInfo
            )
            
            print("nearPeer.start()完了")
            print("NearPeer初期化完了")
            
            await MainActor.run {
                print("状態をdisconnectedに設定")
                connectionState = .disconnected
                clearError()
            }
        } catch {
            print("NearPeer初期化エラー: \(error)")
            print("エラータイプ: \(type(of: error))")
            print("エラー詳細: \(error.localizedDescription)")
            
            await MainActor.run {
                setError("初期化エラー: \(error.localizedDescription)")
                connectionState = .error(error.localizedDescription)
            }
        }
    }
    
    private func monitorConnectionEvents() async {
        for await event in await nearPeer.connectionEvents {
            await handleConnectionEvent(event)
        }
    }
    
    private func monitorDataEvents() async {
        for await event in await nearPeer.dataReceivedEvents {
            await handleDataReceived(event)
        }
    }
    
    @MainActor
    private func handleConnectionEvent(_ event: PeerConnectionEvent) {
        let peerInfo = PeerInfo(displayName: event.peerID.displayName)
        
        print("接続イベント: \(event.peerID.displayName) - \(event.state)")
        
        switch event.state {
        case .connecting:
            print("🟢 接続中: \(event.peerID.displayName)")
            connectionState = .connecting
            
        case .connected:
            print("🟢 接続完了: \(event.peerID.displayName)")
            connectionState = .connected
            if !connectedPeers.contains(peerInfo) {
                connectedPeers.append(peerInfo)
            }
            
        case .notConnected:
            print("🟢 接続終了: \(event.peerID.displayName)")
            connectionState = .disconnected
            connectedPeers.removeAll { $0 == peerInfo }
            
        @unknown default:
            print("🔴 不明な接続状態: \(event.state)")
            connectionState = .error("不明な接続状態")
        }
    }
    
    @MainActor
    private func handleDataReceived(_ event: DataReceivedEvent) {
        print("🔵 データ受信: \(event.peerID.displayName)から \(event.data.count)バイト")
        
        do {
            let decodedText = try JSONDecoder().decode(String.self, from: event.data)
            print("受信メッセージ: \(decodedText)")
            
            let message = MessageData(
                content: decodedText,
                senderName: event.peerID.displayName,
                messageNumber: 0 // 受信メッセージは番号なし
            )
            lastReceivedMessage = message
            clearError()
        } catch {
            print("データデコードエラー: \(error.localizedDescription)")
            setError("データのデコードに失敗: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func setError(_ message: String) {
        lastError = message
    }
}

// MARK: - Error Types
enum NearPeerServiceError: LocalizedError {
    case notConnected
    case emptyMessage
    case connectionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "デバイスが接続されていません"
        case .emptyMessage:
            return "メッセージが空です"
        case .connectionFailed(let reason):
            return "接続に失敗しました: \(reason)"
        }
    }
} 
