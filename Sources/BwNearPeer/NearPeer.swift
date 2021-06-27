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

    private let maxNumPeers: Int
    
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

    public init(maxPeers: Int) {
        maxNumPeers = maxPeers
    }

    /// Start peer communication
    /// - Parameters:
    ///   - serviceName: サービス名
    ///   - displayName: The display name for the local peer
    ///   - discoveryInfo: The discoveryInfo parameter is a dictionary of string key/value pairs that will be advertised for browsers to see.
    ///                  The content of discoveryInfo will be advertised within Bonjour TXT records, so you should keep the dictionary small for better discovery performance.
    public func start(serviceName: String, displayName: String, discoveryInfo: [String: String]? = nil) {

        let serviceTypeName = validate(serviceName: serviceName)

        connection = PearConnection(displayName: displayName, dependency: self)
        advertiser = PearAdvertiser(session: connection.session)
        browser = PearBrowser(session: connection.session, maxPeers: maxNumPeers)

        advertiser.start(serviceType: serviceTypeName, discoveryInfo: discoveryInfo)
        browser.startBrowsing(serviceType: serviceTypeName)
    }

    /// validate
    /// - Parameter service: Must be 1–15 characters long,
    ///                  Can contain only ASCII lowercase letters,
    ///                  numbers, and hyphens, Must contain at least one ASCII letter,
    ///                  Must not begin or end with a hyphen,
    /// - Returns: validated service name
    private func validate(serviceName: String) -> String {
        guard serviceName.count > 0 else {
            return "."
        }

        // Must be 1–15 characters long の他は未実装

        return String(serviceName.prefix(15))
    }
    
    /// 表示名
    /// - Parameter displayName: The maximum allowable length is 63 bytes in UTF-8 encoding
    /// - Returns: validated displayName
    private func validate(displayName: String) -> String {
        return String(displayName.prefix(63))
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
