//
//  PearBrowser.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity

class PeerBrowser: NSObject, MCNearbyServiceBrowserDelegate {
    private let session: MCSession
    private let maxNumPeers: Int
    private var browser: MCNearbyServiceBrowser?

    init(session: MCSession, maxPeers: Int) {
        self.session = session
        self.maxNumPeers = maxPeers

        super.init()
    }

    func start(serviceType: String) {
        browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func stop() {
        browser?.delegate = nil
        browser?.stopBrowsingForPeers()
    }

    // ------------------------------------------------------------------------------------------
    // MARK: - MCNearbyServiceBrowserDelegate
    // ------------------------------------------------------------------------------------------

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
