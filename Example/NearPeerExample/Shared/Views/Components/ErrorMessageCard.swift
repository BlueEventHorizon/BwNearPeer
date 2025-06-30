//
//  ErrorMessageCard.swift
//  NearPeerExample
//
//  Created by Assistant on 2024.
//

import SwiftUI

struct ErrorMessageCard: View {
    let errorMessage: String
    let onDismiss: (() -> Void)?
    
    @State private var isVisible = true
    
    init(errorMessage: String, onDismiss: (() -> Void)? = nil) {
        self.errorMessage = errorMessage
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        Group {
            if isVisible && !errorMessage.isEmpty {
                HStack(spacing: 12) {
                    // エラーアイコン
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                    
                    // エラーメッセージ
                    VStack(alignment: .leading, spacing: 4) {
                        Text("エラー")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // 閉じるボタン
                    if onDismiss != nil {
                        Button(action: dismissError) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.title3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onChange(of: errorMessage) { _, newValue in
            if !newValue.isEmpty {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isVisible = true
                }
            }
        }
    }
    
    private func dismissError() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
        }
        
        // アニメーション完了後にコールバックを実行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

// MARK: - Convenience Extensions
extension ErrorMessageCard {
    /// 自動で消えるエラーメッセージ
    static func autoHiding(
        errorMessage: String,
        duration: TimeInterval = 5.0,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        ErrorMessageCard(errorMessage: errorMessage, onDismiss: onDismiss)
            .task {
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                withAnimation(.easeInOut(duration: 0.3)) {
                    onDismiss?()
                }
            }
    }
}

// MARK: - Toast Style Error Message
struct ToastErrorMessage: View {
    let message: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            if isPresented {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                    
                    Text(message)
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
        .onAppear {
            // 自動で5秒後に非表示にする
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Preview
struct ErrorMessageCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 通常のエラーメッセージ
            ErrorMessageCard(
                errorMessage: "接続に失敗しました。ネットワーク設定を確認してください。",
                onDismiss: {}
            )
            
            // 長いエラーメッセージ
            ErrorMessageCard(
                errorMessage: "サービスの開始に失敗しました。他のアプリが同じサービスを使用している可能性があります。アプリを再起動してもう一度お試しください。"
            )
            
            // 短いエラーメッセージ
            ErrorMessageCard(
                errorMessage: "送信エラー"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 