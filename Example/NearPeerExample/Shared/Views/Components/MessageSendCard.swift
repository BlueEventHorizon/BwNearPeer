//
//  MessageSendCard.swift
//  NearPeerExample
//
//  Created by Assistant on 2024.
//

import SwiftUI

struct MessageSendCard: View {
    @Binding var messageText: String
    let isConnected: Bool
    let isSending: Bool
    let onSend: (String) -> Void
    
    @FocusState private var isTextEditorFocused: Bool
    @State private var isComposing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(isConnected ? .green : .gray)
                    .font(.title2)
                
                Text("メッセージ送信")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isSending {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // メッセージ入力エリア
            VStack(alignment: .leading, spacing: 12) {
                Text("メッセージを入力:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                MessageTextEditor(
                    text: $messageText,
                    isFocused: $isTextEditorFocused,
                    isComposing: $isComposing,
                    isEnabled: isConnected && !isSending
                )
                
                // 送信ボタンエリア
                HStack {
                    // 文字数表示
                    if isComposing && !messageText.isEmpty {
                        Text("\(messageText.count) 文字")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    SendButton(
                        isEnabled: canSend,
                        isSending: isSending,
                        action: {
                            sendMessage()
                        }
                    )
                }
            }
            
            // 接続状態の注意書き
            if !isConnected {
                ConnectionHint()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isComposing ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .onChange(of: messageText) { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                isComposing = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canSend: Bool {
        isConnected && !isSending && !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    private func sendMessage() {
        let textToSend = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSend.isEmpty else { return }
        
        onSend(textToSend)
        isTextEditorFocused = false
        
        // 送信成功後にテキストをクリア（オプション）
        withAnimation(.easeInOut(duration: 0.3)) {
            messageText = ""
            isComposing = false
        }
    }
}

// MARK: - Supporting Views
private struct MessageTextEditor: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    @Binding var isComposing: Bool
    let isEnabled: Bool
    
    var body: some View {
        TextEditor(text: $text)
            .frame(minHeight: 100)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
            )
            .focused(isFocused)
            .disabled(!isEnabled)
            .overlay(
                // プレースホルダー
                Group {
                    if text.isEmpty {
                        VStack {
                            HStack {
                                Text("メッセージを入力してください...")
                                    .foregroundColor(.secondary.opacity(0.7))
                                    .font(.body)
                                    .padding(.leading, 16)
                                    .padding(.top, 20)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused.wrappedValue)
        
    }
    
    private var borderColor: Color {
        if !isEnabled {
            return .gray.opacity(0.3)
        } else if isFocused.wrappedValue {
            return .accentColor
        } else if isComposing {
            return .green.opacity(0.5)
        } else {
            return .gray.opacity(0.3)
        }
    }
}

private struct SendButton: View {
    let isEnabled: Bool
    let isSending: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSending {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.callout)
                }
                
                Text(isSending ? "送信中..." : "送信")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(buttonBackgroundColor)
            )
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
    
    private var buttonBackgroundColor: Color {
        if isSending {
            return .blue.opacity(0.7)
        } else if isEnabled {
            return .blue
        } else {
            return .gray
        }
    }
}

private struct ConnectionHint: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.orange)
                .font(.caption)
            
            Text("メッセージを送信するには、他のデバイスとの接続が必要です")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Preview
struct MessageSendCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // 接続済み状態
            MessageSendCard(
                messageText: .constant("こんにちは！"),
                isConnected: true,
                isSending: false,
                onSend: { _ in }
            )
            
            // 未接続状態
            MessageSendCard(
                messageText: .constant(""),
                isConnected: false,
                isSending: false,
                onSend: { _ in }
            )
            
            // 送信中状態
            MessageSendCard(
                messageText: .constant("送信中のメッセージ"),
                isConnected: true,
                isSending: true,
                onSend: { _ in }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 