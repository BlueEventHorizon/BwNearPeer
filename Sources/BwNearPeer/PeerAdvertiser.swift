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

    init(session: MCSession) {
        self.session = session

        super.init()
    }

    private var advertiser: MCNearbyServiceAdvertiser?

    func start(serviceType: String, discoveryInfo: [NearPeerDiscoveryInfoKey: String]? = nil) {
        if isAdvertising {
            stop()
        }

        isAdvertising = true
        
        self.serviceType = serviceType
        
        if let infos = discoveryInfo {
            infoArray = [String: String]()
            infos.forEach { key, value in
                infoArray?[key.rawValue] = value
            }
        }

        advertiser = MCNearbyServiceAdvertiser(peer: session.myPeerID, discoveryInfo: infoArray, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func stop() {
        if isAdvertising {
            suspend()
        }

        advertiser = nil
    }

    func suspend() {
        guard isAdvertising else {
            return
        }

        advertiser?.delegate = nil
        advertiser?.stopAdvertisingPeer()

        isAdvertising = false
    }

    func resume() {
        guard !isAdvertising else {
            return
        }

        if advertiser == nil, let serviceType = self.serviceType {
            advertiser = MCNearbyServiceAdvertiser(peer: session.myPeerID, discoveryInfo: infoArray, serviceType: serviceType)
        }

        isAdvertising = true

        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    // ------------------------------------------------------------------------------------------
    // MARK: - MCNearbyServiceAdvertiserDelegate
    // ------------------------------------------------------------------------------------------

    /// セッションへの招待を受ける
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}
