# BwNearPeer サンプルアプリ

このディレクトリには、BwNearPeerライブラリの使用方法を示すサンプルアプリケーションが含まれています。

## 技術仕様

**対応プラットフォーム**: iOS 17.0以降 / macOS 14.0以降  
**Swift**: 5.9以降  
**アーキテクチャ**: Swift Concurrency + SwiftUI @Observable

## サンプルアプリ

### NearPeerExample
**用途**: BwNearPeerライブラリのメイン機能デモアプリ  
**対応プラットフォーム**: iOS 17.0以降 / macOS 14.0以降

近距離通信（Multipeer Connectivity）を使用して、同じネットワーク内のデバイス間でリアルタイムにテキストメッセージを送受信できるアプリです。

#### 機能
- **自動ピア検出**: 同じサービスタイプを使用する他のデバイスを自動的に検出
- **リアルタイムメッセージング**: テキストメッセージの双方向送受信
- **接続状態管理**: 接続/切断/再接続の制御
- **エラーハンドリング**: 接続エラーや送信エラーの表示

#### 使い方
1. 2つ以上のデバイス（iOS 17.0以降/macOS 14.0以降）でアプリを起動
2. 自動的に相互接続が開始されます
3. 接続が確立されたら、テキストエリアにメッセージを入力
4. 「送信」ボタンでメッセージを送信
5. 他のデバイスでリアルタイムにメッセージが表示されます

#### 技術的詳細
- Swift Concurrency（`async/await`、`TaskGroup`、`AsyncStream`）を活用
- SwiftUI `@Observable` プロパティラッパーを使用
- 最大1台の他デバイスとの同時接続をサポート
- Actor並行性によるスレッドセーフな処理

---

## セットアップ方法

### 必要な環境
- Xcode 15.0以降
- iOS 17.0以降 / macOS 14.0以降
- Swift 5.9以降

### ビルド・実行手順

#### NearPeerExample
```bash
# ディレクトリに移動
cd Example/NearPeerExample

# Xcodeでプロジェクトを開く
open NearPeerExample.xcodeproj

# または、コマンドラインでビルド
xcodebuild -project NearPeerExample.xcodeproj -scheme NearPeerExample -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## アーキテクチャ

### ディレクトリ構造
```
NearPeerExample/Shared/
├── Models/
│   └── ConnectionState.swift           # 状態管理とデータモデル
├── Configuration/
│   └── NearPeerConfiguration.swift    # 設定管理
├── Services/
│   └── NearPeerService.swift           # NearPeerサービス
├── Views/
│   └── Components/
│       ├── ConnectionStatusCard.swift  # 接続状態表示
│       ├── MessageReceiveCard.swift    # メッセージ受信表示
│       ├── MessageSendCard.swift       # メッセージ送信
│       └── ErrorMessageCard.swift      # エラー表示
└── ContentView.swift                   # メインView
```

### 使用技術
- **Swift Concurrency**: `async/await`、`TaskGroup`、`AsyncStream`
- **SwiftUI**: `@Observable`、`LazyVStack`、`.refreshable`
- **アクセシビリティ**: VoiceOver対応、`.textSelection(.enabled)`

## 実際の使用例

### ピア接続のテスト
1. `NearPeerExample` を2台のデバイスで起動
2. 自動的に接続が確立されることを確認
3. メッセージの送受信をテスト

## トラブルシューティング

### NearPeerExampleで接続できない場合
- 両方のデバイスが同じWi-Fiネットワークに接続されているか確認
- Bluetoothが有効になっているか確認
- ファイアウォール設定を確認

### システム要件エラーが出る場合
- iOS 17.0以降 / macOS 14.0以降で実行しているか確認
- Xcode 15.0以降を使用しているか確認

## リファクタリング情報

このサンプルアプリは大幅にリファクタリングされており、以下の改善が行われています：

- **モダンアーキテクチャ**: 関心の分離、コンポーネント化
- **Swift Concurrency**: 最新の並行処理技術を活用
- **SwiftUI最適化**: `@Observable`による効率的な状態管理
- **コード品質**: メモリリーク対策、エラーハンドリング強化

詳細については `NearPeerExample/REFACTORING.md` をご覧ください。

## ライセンス

このサンプルコードは、BwNearPeerライブラリと同じライセンスの下で提供されています。 