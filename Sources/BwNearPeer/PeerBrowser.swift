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
    private var isBrowsing: Bool = false
    private let dispatch = DispatchQueue(label: "com.beowulf-tech.bwtools.BwNearPeer.browser")
    private var serviceType: String?

    init(session: MCSession, maxPeers: Int) {
        self.session = session
        self.maxNumPeers = maxPeers

        super.init()
    }

    func start(serviceType: String, discoveryInfo: [NearPeerDiscoveryInfoKey: String]?) {
        dispatch.async {
            guard !self.isBrowsing else { return }

            self.serviceType = serviceType
            self.browser = MCNearbyServiceBrowser(peer: self.session.myPeerID, serviceType: serviceType)
            self.browser?.delegate = self
            self.browser?.startBrowsingForPeers()
            self.discoveryInfo = discoveryInfo

            self.isBrowsing = true
        }
    }

    func stop() {
        dispatch.async {
            guard self.isBrowsing else { return }

            self.browser?.delegate = nil
            self.browser?.stopBrowsingForPeers()
            self.browser = nil

            self.isBrowsing = false
        }
    }

    func resume() {
        dispatch.async {
            guard !self.isBrowsing else { return }

            if self.browser == nil, let serviceType = self.serviceType {
                self.browser = MCNearbyServiceBrowser(peer: self.session.myPeerID, serviceType: serviceType)
            }

            self.browser?.delegate = self
            self.browser?.startBrowsingForPeers()
            self.isBrowsing = true
        }
    }

    func suspend() {
        dispatch.async {
            guard self.isBrowsing else { return }

            self.browser?.delegate = nil
            self.browser?.stopBrowsingForPeers()
            self.isBrowsing = false
        }
    }

    private func isMatchDiscoveryInfo(_ info: [String: String]?) -> Bool {
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
        guard isMatchDiscoveryInfo(info) else {
            return
        }

        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // TODO: log.debug("lost \(peerID.displayName)")
    }
}
