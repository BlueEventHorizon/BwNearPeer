//
//  NearPeerWorker.swift
//  NearPeerExample
//
//  Created by Katsuhiko Terada on 2021/06/26.
//

import BwNearPeer
import Combine
import UIKit.UIDevice

class NearPeerWorker: ObservableObject {
    let nearPeer: NearPeer
    var counter: Int = 0

    let discoveryInfo: [NearPeerDiscoveryInfoKey: String] = [.identifier: "com.beowulf-tech.sirudoor.discovery.name", .passcode: "4989"]

    @Published var peers: [String] = [String]()
    @Published var peerName: String = ""
    @Published var receivedText: String = "まだ受信していません"

    init() {
        nearPeer = NearPeer(maxPeers: 1)

        nearPeer.start(serviceType: "nearpeer", displayName: UIDevice.current.name, myDiscoveryInfo: discoveryInfo, targetDiscoveryInfo: discoveryInfo)
        nearPeer.onConnected { peer in

            // TODO: 切断された時の処理を追加すること
            self.peers.append(peer.displayName)
        }

        nearPeer.onReceived { peer, data in
            guard let data = data else {
                log.error("データがありません")
                return
            }

            self.peerName = peer.displayName

            if let decodedText = try? JSONDecoder().decode(String.self, from: data) {
                self.receivedText = decodedText
            } else {
                log.error("decode失敗")
            }
        }
    }

    func send(text: String) {
        log.entered(self)

        if let encodedData: Data = try? JSONEncoder().encode("\(counter)回目 \(text)") {
            nearPeer.send(encodedData)
            counter += 1
        } else {
            log.error("encode失敗")
        }
    }
}
