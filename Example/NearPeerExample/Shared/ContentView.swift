//
//  ContentView.swift
//  Shared
//
//  Created by Katsuhiko Terada on 2021/06/26.
//  Refactored by Assistant on 2024.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @State private var sendText = "（このテキストを送信することができます）"
    @State private var isSending = false
    @State private var nearPeerService = NearPeerService()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 接続状態セクション
                    ConnectionStatusCard(
                        connectionState: nearPeerService.connectionState,
                        peersText: nearPeerService.peersDisplayText,
                        onReconnect: handleReconnect,
                        onDisconnect: handleDisconnect
                    )
                    
                    // 受信メッセージセクション
                    MessageReceiveCard(message: nearPeerService.lastReceivedMessage)
                    
                    // 送信メッセージセクション
                    MessageSendCard(
                        messageText: $sendText,
                        isConnected: nearPeerService.isConnected,
                        isSending: isSending,
                        onSend: handleSendMessage
                    )
                    
                    // エラーメッセージ
                    if !nearPeerService.lastError.isEmpty {
                        ErrorMessageCard(
                            errorMessage: nearPeerService.lastError,
                            onDismiss: {
                                nearPeerService.clearError()
                            }
                        )
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Near Peer Example")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await handleRefresh()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Actions
    private func handleSendMessage(_ message: String) {
        guard !isSending else { return }
        
        isSending = true
        
        Task {
            do {
                try await nearPeerService.sendMessage(message)
            } catch {
                // エラーはサービス内で処理される
                print("送信エラー: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                isSending = false
            }
        }
    }
    
    private func handleReconnect() {
        Task {
            do {
                try await nearPeerService.reconnect()
            } catch {
                print("再接続エラー: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleDisconnect() {
        Task {
            await nearPeerService.disconnect()
        }
    }
    
    private func handleRefresh() async {
        // プルツーリフレッシュでの再接続試行
        if !nearPeerService.isConnected {
            handleReconnect()
        }
        
        // 少し待ってからリフレッシュを完了
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            ContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
