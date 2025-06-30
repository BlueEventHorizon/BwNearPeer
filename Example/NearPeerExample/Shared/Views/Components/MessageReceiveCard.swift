//
//  MessageReceiveCard.swift
//  NearPeerExample
//
//  Created by Assistant on 2024.
//

import SwiftUI

struct MessageReceiveCard: View {
    let message: MessageData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("受信メッセージ")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // メッセージ情報
            if let message = message {
                VStack(alignment: .leading, spacing: 12) {
                    // メタ情報
                    MessageMetaInfo(message: message)
                    
                    // メッセージ本文
                    MessageContent(content: message.content)
                }
            } else {
                EmptyMessageState()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Supporting Views
private struct MessageMetaInfo: View {
    let message: MessageData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            InfoRow(
                title: "送信元",
                value: message.senderName,
                icon: "person.circle"
            )
            
            InfoRow(
                title: "受信時刻",
                value: formatTime(message.timestamp),
                icon: "clock"
            )
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.caption)
                .frame(width: 12)
            
            Text(title + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

private struct MessageContent: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メッセージ:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                .textSelection(.enabled)
        }
    }
}

private struct EmptyMessageState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.open")
                .font(.largeTitle)
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("まだメッセージを受信していません")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Preview
struct MessageReceiveCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // メッセージありの状態
            MessageReceiveCard(
                message: MessageData(
                    content: "1回目 こんにちは！テストメッセージです。",
                    senderName: "iPhone 14 Pro",
                    messageNumber: 1
                )
            )
            
            // メッセージなしの状態
            MessageReceiveCard(message: nil)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 