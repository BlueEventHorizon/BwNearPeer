//
//  ContentView.swift
//  Shared
//
//  Created by Katsuhiko Terada on 2021/06/26.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var nearPeerWorker: NearPeerWorker = NearPeerWorker()

    @State var sendText: String = "このテキストを送信することができます"
    
    var body: some View {
        
        NavigationView {
            VStack(alignment: .leading, spacing: 25) {
                
                HStack {
                    Image(systemName: "text.bubble")
                        .foregroundColor(.blue)
                    Text(nearPeerWorker.recievedText)
                        .foregroundColor(.blue)
                        .lineLimit(nil)
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

                HStack() {
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
