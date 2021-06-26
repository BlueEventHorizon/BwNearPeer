//
//  NearPeer.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity

public class NearPeer: PearConnectionDependency {

    public typealias ConnectionHandler = ((_ peerID: MCPeerID) -> Void)
    public typealias DataRecieveHandler = ((_ peerID: MCPeerID, _ data: Data?) -> Void)

    private var onConnecting: ConnectionHandler?
    private var onConnect: ConnectionHandler?
    private var onDisconnect: ConnectionHandler?
    private var onRecieved: DataRecieveHandler?

    private var connection: PearConnection!
    private var advertiser: PearAdvertiser!
    private var browser: PearBrowser!
    
    // ------------------------------------------------------------------------------------------
    // MARK: - public
    // ------------------------------------------------------------------------------------------

    public init() {}

    public func start(serviceType: String, displayName: String, discoveryInfo: [String: String]? = nil) {

        connection = PearConnection(displayName: displayName, dependency: self)
        advertiser = PearAdvertiser(session: connection.session)
        browser = PearBrowser(session: connection.session)

        advertiser.start(serviceType: serviceType, discoveryInfo: discoveryInfo)
        browser.startBrowsing(serviceType: serviceType)
    }

    public func stop() {
        advertiser.stop()
        browser.stopBrowsing()
        connection.disconnect()
    }
    
    public func stopAdvertising() {
        advertiser.stop()
    }
    
    public func restartAdvertising() {
        advertiser.restart()
    }

    public func onConnecting(_ handler: ConnectionHandler?){
        onConnecting = handler
    }

    public func onConnect(_ handler: ConnectionHandler?){
        onConnect = handler
    }

    public func onDisconnect(_ handler: ConnectionHandler?){
        onDisconnect = handler
    }

    public func onRecieved(handler: DataRecieveHandler?){
        onRecieved = handler
    }
    
    
    public func sendData(_ data: Data) {
        let peers = connection.session.connectedPeers

        guard !peers.isEmpty else {
            return
        }

        do {
            try connection.session.send(data, toPeers: peers, with: .reliable)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // ------------------------------------------------------------------------------------------
    // MARK: - Internal
    // ------------------------------------------------------------------------------------------

    func connecting(with peer: MCPeerID) {
        if let onConnecting = onConnecting {
            DispatchQueue.main.async {
                onConnecting(peer)
            }
        }
    }

    func didConnect(with peer: MCPeerID) {
        if let onConnect = onConnect {
            DispatchQueue.main.async {
                onConnect(peer)
            }
        }
    }

    func didDisconnect(with peer: MCPeerID) {
        if let onDisconnect = onDisconnect {
            DispatchQueue.main.async {
                onDisconnect(peer)
            }
        }
    }

    func didReceiveData(_ data: Data, from peer: MCPeerID) {
        if let onRecieved = onRecieved {
            DispatchQueue.main.async {
                onRecieved(peer, data)
            }
        }
    }
}
