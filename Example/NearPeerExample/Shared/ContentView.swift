//
//  ContentView.swift
//  Shared
//
//  Created by Katsuhiko Terada on 2021/06/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var nearPeerWorker: NearPeerWorker = NearPeerWorker()
    @State var sendText: String = "（このテキストを送信することができます）"

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundColor(.blue)
                        Text("受信")
                            .bold()
                    }

                    Text("送信元: \(nearPeerWorker.peerName)")
                        .foregroundColor(.gray)
                        .bold()
                        .font(.footnote)

                    if nearPeerWorker.peerName.isEmpty {
                        Text("受信時刻: ")
                            .foregroundColor(.gray)
                            .bold()
                            .font(.footnote)
                    } else {
                        Text("受信時刻: \(Date())")
                            .foregroundColor(.gray)
                            .bold()
                            .font(.footnote)
                    }

                    Text("受信メッセージ:")
                        .foregroundColor(.gray)
                        .bold()
                        .font(.footnote)

                    Text(nearPeerWorker.recievedText)
                        .foregroundColor(.blue)
                        .font(.body)
                        .lineLimit(10)
                }

                Rectangle()
                    .fill(Color(UIColor.systemGray3))
                    .frame(height: 1.1)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundColor(.blue)
                        Text("送信")
                            .bold()
                    }

                    HStack {
                        TextEditor(text: $sendText)
                            .frame(height: 100)
                            .lineLimit(nil)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                }

                HStack {
                    Spacer()
                    Button {
                        nearPeerWorker.send(text: sendText)
                    } label: {
                        BorderedText(text: "送信")
                    }
                }

                Spacer()
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 20)
            .navigationBarTitle("Near Peer Example", displayMode: .inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
