//
//  NearPeerWorker.swift
//  NearPeerExample
//
//  Created by Katsuhiko Terada on 2021/06/26.
//

import BwNearPeer
import Combine
import Foundation
import UIKit.UIDevice

class NearPeerWorker: ObservableObject {
    let nearPeer: NearPeer

    @Published var peerName: String = ""
    @Published var recievedText: String = "まだ受信していませんまだ受信していませんまだ受信していませんまだ受信していませんまだ受信していませんまだ受信していません"

    init() {
        nearPeer = NearPeer(maxPeers: 1)

        nearPeer.start(serviceName: "nearpeer", displayName: UIDevice.current.name, discoveryInfo: nil)
        nearPeer.onRecieved { peer, data in
            guard let data = data else {
                log.error("データがありません")
                return
            }

            self.peerName = peer.displayName

            if let decodedText = try? JSONDecoder().decode(String.self, from: data) {
                self.recievedText = decodedText
            } else {
                log.error("decode失敗")
            }
        }
    }

    func send(text: String) {
        log.entered(self)

        if let encodedData: Data = try? JSONEncoder().encode(text) {
            nearPeer.send(encodedData)
        } else {
            log.error("encode失敗")
        }
    }
}
