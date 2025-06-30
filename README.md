# BwNearPeer

[![Release](https://img.shields.io/github/v/release/BlueEventHorizon/BwNearPeer)](https://github.com/BlueEventHorizon/BwNearPeer/releases/latest)
[![License](https://img.shields.io/github/license/BlueEventHorizon/BwNearPeer)](https://github.com/BlueEventHorizon/BwNearPeer/blob/main/LICENSE)
![](https://img.shields.io/badge/Platforms-iOS%2017.6%2B-blue)
![](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange)
[![Twitter](https://img.shields.io/twitter/follow/k2_moons?style=social)](https://twitter.com/k2_moons)

BwNearPeer is a library that makes the MultipeerConnectivity framework easy to use with modern Swift concurrency. 

The MultipeerConnectivity framework uses infrastructure Wi-Fi networks, peer-to-peer Wi-Fi, and Bluetooth personal area networks for the underlying transport.
And it allows easy communication between devices.

You can see detail about The MultipeerConnectivity in https://developer.apple.com/documentation/multipeerconnectivity

## 🆕 iOS 17.6+ モダン対応

iOS 17.6以降では、以下の新機能をサポートしています：

### 主要な改善点

- **Swift Concurrency対応**: `async/await`パターンによる非同期処理
- **Actor isolation**: スレッドセーフなデータアクセス
- **AsyncStream**: リアルタイムイベントストリーミング
- **@Observable**: SwiftUI用の新しいObservableマクロ対応
- **強化されたセキュリティ**: 暗号化必須設定
- **エラーハンドリング**: 構造化されたエラー処理
- **型安全性**: より安全なAPI設計

## 要件

- **iOS 17.0+** (推奨: iOS 17.6+)
- **macOS 14.0+**
- **Swift 5.9+**
- **Xcode 15.0+**

## インストール

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/BlueEventHorizon/BwNearPeer.git", from: "2.0.0")
]
```

## 使用方法

### モダンなSwift Concurrency API（iOS 17.6+）

```swift
import BwNearPeer
import SwiftUI

@Observable
class PeerManager {
    private let nearPeer = NearPeer(maxPeers: 1)
    var peers: [String] = []
    var receivedMessages: [String] = []
    var isConnected = false
    
    init() {
        Task {
            await startMonitoring()
            try await startService()
        }
    }
    
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
    
    private func startService() async throws {
        let discoveryInfo: [NearPeerDiscoveryInfoKey: String] = [
            .identifier: "com.example.app",
            .passcode: "1234"
        ]
        
        try await nearPeer.start(
            serviceType: "myservice",
            displayName: "MyDevice",
            myDiscoveryInfo: discoveryInfo,
            targetDiscoveryInfo: discoveryInfo
        )
    }
    
    @MainActor
    private func handleConnectionEvent(_ event: PeerConnectionEvent) {
        switch event.state {
        case .connected:
            isConnected = true
            peers.append(event.peerID.displayName)
        case .notConnected:
            isConnected = false
            peers.removeAll { $0 == event.peerID.displayName }
        default:
            break
        }
    }
    
    @MainActor
    private func handleDataReceived(_ event: DataReceivedEvent) {
        if let message = try? JSONDecoder().decode(String.self, from: event.data) {
            receivedMessages.append(message)
        }
    }
    
    func sendMessage(_ text: String) {
        Task {
            try await nearPeer.send(text)
        }
    }
}
```

### SwiftUIでの使用

```swift
struct ContentView: View {
    @State private var peerManager = PeerManager()
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            Text("接続状態: \(peerManager.isConnected ? "接続中" : "未接続")")
            
            List(peerManager.receivedMessages, id: \.self) { message in
                Text(message)
            }
            
            HStack {
                TextField("メッセージ", text: $messageText)
                Button("送信") {
                    peerManager.sendMessage(messageText)
                    messageText = ""
                }
                .disabled(!peerManager.isConnected)
            }
        }
    }
}
```

### レガシーAPI（下位互換性）

既存のコードとの互換性を保つため、レガシーAPIも利用可能です：

```swift
import BwNearPeer

class LegacyPeerManager: ObservableObject {
    private let nearPeer = NearPeerLegacy(maxPeers: 1)
    @Published var receivedText = ""
    
    init() {
        nearPeer.onConnected { peer in
            print("接続: \(peer.displayName)")
        }
        
        nearPeer.onReceived { peer, data in
            if let data = data,
               let text = try? JSONDecoder().decode(String.self, from: data) {
                self.receivedText = text
            }
        }
        
        nearPeer.start(
            serviceType: "myservice",
            displayName: "MyDevice",
            myDiscoveryInfo: [.identifier: "com.example.app"],
            targetDiscoveryInfo: [.identifier: "com.example.app"]
        )
    }
    
    func send(text: String) {
        if let data = try? JSONEncoder().encode(text) {
            nearPeer.send(data)
        }
    }
}
```

## エラーハンドリング

iOS 17.6対応版では、構造化されたエラーハンドリングをサポートしています：

```swift
do {
    try await nearPeer.start(serviceType: "myservice", displayName: "MyDevice")
    try await nearPeer.send("Hello World")
} catch NearPeerError.invalidServiceType(let serviceType) {
    print("無効なサービスタイプ: \(serviceType)")
} catch NearPeerError.peerNotConnected {
    print("ピアが接続されていません")
} catch {
    print("エラー: \(error)")
}
```

## 利用できるエラータイプ

- `NearPeerError.invalidServiceType`: 無効なサービスタイプ
- `NearPeerError.invalidDisplayName`: 無効な表示名
- `NearPeerError.sessionNotFound`: セッションが見つからない
- `NearPeerError.peerNotConnected`: ピアが接続されていない
- `NearPeerError.encodingFailed`: エンコードに失敗
- `NearPeerError.sendingFailed`: 送信に失敗
- `NearPeerError.startupFailed`: サービス開始に失敗

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.