//
//  NearPeerWorker.swift
//  NearPeerExample
//
//  Created by Katsuhiko Terada on 2021/06/26.
//

import Foundation
import Combine
import BwNearPeer
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
                return
            }
            
            self.peerName = peer.displayName
            
            if let decodedText = try? JSONDecoder().decode(String.self, from: data) {
                self.recievedText = decodedText
            }
        }
    }

    func send(text: String)  {
        log.entered(self)

        let data: Data = try! JSONEncoder().encode(text)

        nearPeer.sendData(data)
    }
}
