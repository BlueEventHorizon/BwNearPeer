//
//  PearAdvertiser.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity

class PeerAdvertiser: NSObject, MCNearbyServiceAdvertiserDelegate {
    let session: MCSession
    var isAdvertising: Bool = false

    init(session: MCSession) {
        self.session = session

        super.init()
    }

    private var advertiser: MCNearbyServiceAdvertiser?

    func start(serviceType: String, discoveryInfo: [String: String]? = nil) {
        guard !isAdvertising else {
            return
        }

        isAdvertising = true
        advertiser = MCNearbyServiceAdvertiser(peer: session.myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func stop() {
        guard isAdvertising else {
            return
        }

        advertiser?.delegate = nil
        advertiser?.stopAdvertisingPeer()

        isAdvertising = false
    }

    func restart() {
        if isAdvertising {
            stop()
        }

        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    // ------------------------------------------------------------------------------------------
    // MARK: - MCNearbyServiceAdvertiserDelegate
    // ------------------------------------------------------------------------------------------

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}
