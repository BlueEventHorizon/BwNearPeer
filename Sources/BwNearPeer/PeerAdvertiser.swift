//
//  PearAdvertiser.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity

class PeerAdvertiser: NSObject, MCNearbyServiceAdvertiserDelegate {
    private let session: MCSession
    private var isAdvertising: Bool = false
    private var serviceType: String?
    private var infoArray: [String: String]?
    private let dispatch = DispatchQueue(label: "com.beowulf-tech.bwtools.BwNearPeer.advertiser")

    init(session: MCSession) {
        self.session = session

        super.init()
    }

    private var advertiser: MCNearbyServiceAdvertiser?

    func start(serviceType: String, discoveryInfo: [NearPeerDiscoveryInfoKey: String]? = nil) {
        dispatch.async {
            guard !self.isAdvertising else { return }

            self.isAdvertising = true

            self.serviceType = serviceType

            if let infos = discoveryInfo {
                self.infoArray = [String: String]()
                infos.forEach { key, value in
                    self.infoArray?[key.rawValue] = value
                }
            }

            self.advertiser = MCNearbyServiceAdvertiser(peer: self.session.myPeerID, discoveryInfo: self.infoArray, serviceType: serviceType)
            self.advertiser?.delegate = self
            self.advertiser?.startAdvertisingPeer()
        }
    }

    func stop() {
        dispatch.async {
            guard self.isAdvertising else { return }

            self.advertiser?.delegate = nil
            self.advertiser?.stopAdvertisingPeer()

            self.advertiser = nil

            self.isAdvertising = false
        }
    }

    func resume() {
        dispatch.async {
            guard !self.isAdvertising else { return }
            guard self.advertiser != nil else { return }

            self.isAdvertising = true

            self.advertiser?.delegate = self
            self.advertiser?.startAdvertisingPeer()
        }
    }

    func suspend() {
        dispatch.async {
            guard self.isAdvertising else { return }

            self.advertiser?.delegate = nil
            self.advertiser?.stopAdvertisingPeer()

            self.isAdvertising = false
        }
    }

    // ------------------------------------------------------------------------------------------
    // MARK: - MCNearbyServiceAdvertiserDelegate
    // ------------------------------------------------------------------------------------------

    /// セッションへの招待を受ける
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}
