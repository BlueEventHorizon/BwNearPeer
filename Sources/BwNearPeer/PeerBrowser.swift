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
    private var discoveryInfo: [NearPeerDiscoveryInfoKey: String]?

    init(session: MCSession, maxPeers: Int) {
        self.session = session
        self.maxNumPeers = maxPeers

        super.init()
    }

    func start(serviceType: String, discoveryInfo: [NearPeerDiscoveryInfoKey: String]?) {
        browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        self.discoveryInfo = discoveryInfo
    }

    func stop() {
        browser?.delegate = nil
        browser?.stopBrowsingForPeers()
    }

    private func isMutchDiscoveryInfo(_ info: [String: String]?) -> Bool {
        guard let discoveryInfo = discoveryInfo else {
            // discoveryInfoが定義されていない場合は、なんでも受け入れる
            return true
        }

        guard let info = info else {
            // discoveryInfoが定義されていて、ブラウズしたpeerがdiscoveryInfoを持っていない場合は、接続しない
            return false
        }

        for key in discoveryInfo.keys {
            if discoveryInfo[key] == info[key.rawValue] {
                continue
            } else {
                // ひとつでも一致しない場合は、接続しない
                return false
            }
        }

        return true
    }

    // ------------------------------------------------------------------------------------------
    // MARK: - MCNearbyServiceBrowserDelegate
    // ------------------------------------------------------------------------------------------

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard isMutchDiscoveryInfo(info) else {
            return
        }

        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // TODO:  log.debug("lost \(peerID.displayName)")
    }
}
