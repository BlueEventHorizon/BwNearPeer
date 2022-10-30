//
//  ContentView.swift
//  InRoomLogApp
//
//  Created by Katsuhiko Terada on 2022/10/27.
//

import SwiftUI
import InRoomLogger

struct ContentView: View {
    @State var logger = Logger()

    var body: some View {
        VStack {
            Button {
                logger.debug("送信!!")
            } label: {
                Text("送信")
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
