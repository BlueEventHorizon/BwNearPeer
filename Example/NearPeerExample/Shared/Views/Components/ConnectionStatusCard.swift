//
//  ConnectionStatusCard.swift
//  NearPeerExample
//
//  Created by Assistant on 2024.
//

import SwiftUI

struct ConnectionStatusCard: View {
    let connectionState: ConnectionState
    let peersText: String
    let onReconnect: () -> Void
    let onDisconnect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                connectionIcon
                Text("接続状態")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 制御ボタン
                connectionControlButtons
            }
            
            // 状態情報
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(
                    title: "状態",
                    value: connectionState.displayText,
                    valueColor: statusColor
                )
                
                StatusRow(
                    title: "接続先",
                    value: peersText,
                    valueColor: connectionState.isConnected ? .primary : .secondary
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    private var connectionIcon: some View {
        Image(systemName: iconName)
            .foregroundColor(iconColor)
            .font(.title2)
    }
    
    private var connectionControlButtons: some View {
        HStack(spacing: 8) {
            Button("再接続", action: onReconnect)
                .buttonStyle(SecondaryButtonStyle())
                .disabled(connectionState.isConnected || connectionState.isConnecting)
            
            Button("切断", action: onDisconnect)
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!connectionState.isConnected)
        }
    }
    
    private var iconName: String {
        switch connectionState {
        case .disconnected:
            return "wifi.slash"
        case .connecting:
            return "wifi.exclamationmark"
        case .connected:
            return "wifi"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var iconColor: Color {
        switch connectionState {
        case .disconnected:
            return .orange
        case .connecting:
            return .yellow
        case .connected:
            return .green
        case .error:
            return .red
        }
    }
    
    private var statusColor: Color {
        switch connectionState {
        case .connected:
            return .green
        case .error:
            return .red
        default:
            return .secondary
        }
    }
    
    private var backgroundColor: Color {
        Color(.systemGray6)
    }
    
    private var borderColor: Color {
        switch connectionState {
        case .connected:
            return .green.opacity(0.3)
        case .error:
            return .red.opacity(0.3)
        default:
            return .clear
        }
    }
}

// MARK: - Supporting Views
private struct StatusRow: View {
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(valueColor)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

// MARK: - Button Styles
private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(configuration.isPressed ? 0.3 : 0.1))
            )
            .foregroundColor(.accentColor)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct ConnectionStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ConnectionStatusCard(
                connectionState: .connected,
                peersText: "iPhone 14 Pro",
                onReconnect: {},
                onDisconnect: {}
            )
            
            ConnectionStatusCard(
                connectionState: .disconnected,
                peersText: "なし",
                onReconnect: {},
                onDisconnect: {}
            )
            
            ConnectionStatusCard(
                connectionState: .error("接続エラー"),
                peersText: "なし",
                onReconnect: {},
                onDisconnect: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 