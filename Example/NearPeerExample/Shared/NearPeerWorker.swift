//
//  NearPeerWorker.swift
//  NearPeerExample
//
//  Created by Katsuhiko Terada on 2021/06/26.
//

import BwNearPeer
import SwiftUI
import UIKit.UIDevice

/// iOS17.6対応のNearPeerWorker
@available(iOS 17.0, macOS 14.0, *)
@Observable
class NearPeerWorker {
    private let nearPeer: NearPeer
    private var counter: Int = 0
    
    let discoveryInfo: [NearPeerDiscoveryInfoKey: String] = [
        .identifier: "com.beowulf-tech.sirudoor.discovery.name",
        .passcode: "4989"
    ]
    
    // @Published の代わりに @Observable を使用
    var peers: [String] = []
    var peerName: String = ""
    var receivedText: String = "まだ受信していません"
    var connectionStatus: String = "未接続"
    var isConnected: Bool = false
    var errorMessage: String = ""
    
    init() {
        nearPeer = NearPeer(maxPeers: 1)
        
        // イベントストリームの監視を開始
        Task {
            await startMonitoring()
        }
        
        // NearPeerを開始
        Task {
            do {
                try await nearPeer.start(
                    serviceType: "nearpeer",
                    displayName: UIDevice.current.name,
                    myDiscoveryInfo: discoveryInfo,
                    targetDiscoveryInfo: discoveryInfo
                )
                await updateConnectionStatus("サービス開始")
            } catch {
                await updateErrorMessage("開始エラー: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        Task {
            await nearPeer.stop()
        }
    }
    
    /// イベントストリームの監視を開始
    @MainActor
    private func startMonitoring() async {
        // 接続イベントの監視
        Task {
            for await event in nearPeer.connectionEvents {
                await handleConnectionEvent(event)
            }
        }
        
        // データ受信イベントの監視
        Task {
            for await event in nearPeer.dataReceivedEvents {
                await handleDataReceived(event)
            }
        }
    }
    
    /// 接続イベントの処理
    @MainActor
    private func handleConnectionEvent(_ event: PeerConnectionEvent) async {
        switch event.state {
        case .connecting:
            connectionStatus = "接続中..."
            isConnected = false
            
        case .connected:
            connectionStatus = "接続済み"
            isConnected = true
            
            // 接続済みピアのリストを更新
            if !peers.contains(event.peerID.displayName) {
                peers.append(event.peerID.displayName)
            }
            
        case .notConnected:
            connectionStatus = "切断済み"
            isConnected = false
            
            // 切断されたピアをリストから削除
            peers.removeAll { $0 == event.peerID.displayName }
            
        @unknown default:
            connectionStatus = "不明な状態"
            isConnected = false
        }
    }
    
    /// データ受信イベントの処理
    @MainActor
    private func handleDataReceived(_ event: DataReceivedEvent) async {
        peerName = event.peerID.displayName
        
        do {
            let decodedText = try JSONDecoder().decode(String.self, from: event.data)
            receivedText = decodedText
            errorMessage = ""
        } catch {
            errorMessage = "データのデコードに失敗しました: \(error.localizedDescription)"
        }
    }
    
    /// メッセージを送信
    func send(text: String) {
        Task {
            do {
                let message = "\(counter)回目 \(text)"
                try await nearPeer.send(message)
                
                await incrementCounter()
                await updateErrorMessage("")
                
            } catch {
                await updateErrorMessage("送信エラー: \(error.localizedDescription)")
            }
        }
    }
    
    /// 接続を再開
    func reconnect() {
        Task {
            do {
                try await nearPeer.resume()
                await updateErrorMessage("")
            } catch {
                await updateErrorMessage("再接続エラー: \(error.localizedDescription)")
            }
        }
    }
    
    /// 接続を停止
    func disconnect() {
        Task {
            await nearPeer.suspend()
            await updateConnectionStatus("停止済み")
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func updateConnectionStatus(_ status: String) {
        connectionStatus = status
    }
    
    @MainActor
    private func updateErrorMessage(_ message: String) {
        errorMessage = message
    }
    
    @MainActor
    private func incrementCounter() {
        counter += 1
    }
}

/// iOS17.6未満の互換性のためのレガシーWorker
@available(iOS, deprecated: 17.0, message: "iOS17.6以降では新しいNearPeerWorkerを使用してください")
class NearPeerWorkerLegacy: ObservableObject {
    let nearPeer: NearPeerLegacy
    var counter: Int = 0

    let discoveryInfo: [NearPeerDiscoveryInfoKey: String] = [
        .identifier: "com.beowulf-tech.sirudoor.discovery.name",
        .passcode: "4989"
    ]

    @Published var peers: [String] = [String]()
    @Published var peerName: String = ""
    @Published var receivedText: String = "まだ受信していません"

    init() {
        nearPeer = NearPeerLegacy(maxPeers: 1)

        nearPeer.start(
            serviceType: "nearpeer",
            displayName: UIDevice.current.name,
            myDiscoveryInfo: discoveryInfo,
            targetDiscoveryInfo: discoveryInfo
        )
        
        nearPeer.onConnected { peer in
            self.peers.append(peer.displayName)
        }

        nearPeer.onReceived { peer, data in
            guard let data = data else {
                print("データがありません")
                return
            }

            self.peerName = peer.displayName

            if let decodedText = try? JSONDecoder().decode(String.self, from: data) {
                self.receivedText = decodedText
            } else {
                print("decode失敗")
            }
        }
    }

    func send(text: String) {
        if let encodedData: Data = try? JSONEncoder().encode("\(counter)回目 \(text)") {
            nearPeer.send(encodedData)
            counter += 1
        } else {
            print("encode失敗")
        }
    }
}
