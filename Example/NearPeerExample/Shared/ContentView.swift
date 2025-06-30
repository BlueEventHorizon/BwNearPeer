//
//  ContentView.swift
//  Shared
//
//  Created by Katsuhiko Terada on 2021/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var nearPeerWorker: NearPeerWorker
    @State private var sendText: String = "（このテキストを送信することができます）"
    
    // iOS17.6対応: 新しいNearPeerWorkerを使用
    init() {
        if #available(iOS 17.0, macOS 14.0, *) {
            _nearPeerWorker = State(initialValue: NearPeerWorker())
        } else {
            // iOS17.6未満の場合は、レガシーワーカーを使用
            // 注: この部分は実際のプロジェクトでは適切に処理する必要があります
            _nearPeerWorker = State(initialValue: NearPeerWorker())
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 接続状態セクション
                    ConnectionStatusView(worker: nearPeerWorker)
                    
                    Divider()
                    
                    // 受信セクション
                    ReceiveSection(worker: nearPeerWorker)
                    
                    Divider()
                    
                    // 送信セクション
                    SendSection(sendText: $sendText, worker: nearPeerWorker)
                    
                    // エラーメッセージ表示
                    if !nearPeerWorker.errorMessage.isEmpty {
                        ErrorMessageView(message: nearPeerWorker.errorMessage)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
            }
            .navigationBarTitle("Near Peer Example", displayMode: .inline)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // iOS17.6対応
    }
}

// MARK: - Connection Status View

struct ConnectionStatusView: View {
    let worker: NearPeerWorker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(worker.isConnected ? .green : .orange)
                Text("接続状態")
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                // 接続制御ボタン
                HStack {
                    Button("再接続") {
                        worker.reconnect()
                    }
                    .buttonStyle(.bordered)
                    .disabled(worker.isConnected)
                    
                    Button("切断") {
                        worker.disconnect()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!worker.isConnected)
                }
            }
            
            Text("状態: \(worker.connectionStatus)")
                .font(.body)
                .foregroundColor(.secondary)
            
            if !worker.peers.isEmpty {
                Text("接続先: \(worker.peers.joined(separator: ", "))")
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Text("接続先: なし")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Receive Section

struct ReceiveSection: View {
    let worker: NearPeerWorker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.blue)
                Text("受信")
                    .font(.headline)
                    .bold()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("送信元: \(worker.peerName.isEmpty ? "未受信" : worker.peerName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .bold()
                
                Text("受信時刻: \(worker.peerName.isEmpty ? "未受信" : formatCurrentTime())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("受信メッセージ:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .bold()
                
                Text(worker.receivedText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .textSelection(.enabled) // iOS17.6対応: テキスト選択可能
            }
        }
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: Date())
    }
}

// MARK: - Send Section

struct SendSection: View {
    @Binding var sendText: String
    let worker: NearPeerWorker
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "arrow.up.circle")
                    .foregroundColor(.green)
                Text("送信")
                    .font(.headline)
                    .bold()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("送信メッセージ:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .bold()
                
                TextEditor(text: $sendText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTextEditorFocused ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .focused($isTextEditorFocused)
                
                HStack {
                    Spacer()
                    
                    Button {
                        if !sendText.isEmpty {
                            worker.send(text: sendText)
                            // 送信後にフォーカスを外す
                            isTextEditorFocused = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("送信")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(worker.isConnected ? Color.blue : Color.gray)
                        .cornerRadius(25)
                    }
                    .disabled(!worker.isConnected || sendText.isEmpty)
                    .animation(.easeInOut(duration: 0.2), value: worker.isConnected)
                }
            }
        }
    }
}

// MARK: - Error Message View

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            ContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        } else {
            Text("iOS 17.0以降でプレビューできます")
        }
    }
}
