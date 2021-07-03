//
//  NearPeer.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity

public enum NearPeerDiscoveryInfoKey: String {
    case identifier
    case passcode
}

public class NearPeer: PeerConnectionDependency {
    public typealias ConnectionHandler = ((_ peerID: MCPeerID) -> Void)
    public typealias DataRecieveHandler = ((_ peerID: MCPeerID, _ data: Data?) -> Void)

    private let maxNumPeers: Int

    private var connectingHandler: ConnectionHandler?
    private var connectedHandler: ConnectionHandler?
    private var disconnectedHandler: ConnectionHandler?
    private var recievedHandler: DataRecieveHandler?

    private var connection: PeerConnection?
    private var advertiser: PeerAdvertiser?
    private var browser: PeerBrowser?

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
    public func start(serviceName: String, displayName: String, discoveryInfo: [NearPeerDiscoveryInfoKey: String]? = nil) {
        let validatedServiceName = validate(serviceName: serviceName)
        let validatedDisplayName = validate(displayName: displayName)

        self.connection = PeerConnection(displayName: validatedDisplayName, dependency: self)
        
        guard let connection = connection else { return }

        advertiser = PeerAdvertiser(session: connection.session)
        browser = PeerBrowser(session: connection.session, maxPeers: maxNumPeers)

        advertiser?.start(serviceType: validatedServiceName, discoveryInfo: discoveryInfo)
        browser?.start(serviceType: validatedServiceName, discoveryInfo: discoveryInfo)
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
        advertiser?.stop()
        browser?.stop()
        connection?.disconnect()
    }

    public func invalidate() {
        stop()
    }

    public func stopAdvertising() {
        advertiser?.stop()
    }

    public func restartAdvertising() {
        advertiser?.restart()
    }

    public func onConnecting(_ handler: ConnectionHandler?) {
        connectingHandler = handler
    }

    public func onConnected(_ handler: ConnectionHandler?) {
        connectedHandler = handler
    }

    public func onDisconnect(_ handler: ConnectionHandler?) {
        disconnectedHandler = handler
    }

    public func onRecieved(handler: DataRecieveHandler?) {
        recievedHandler = handler
    }

    public func send(_ data: Data) {
        guard let connection = connection else {
            return
        }

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
        if let connectingHandler = connectingHandler {
            DispatchQueue.main.async {
                connectingHandler(peer)
            }
        }
    }

    func connected(with peer: MCPeerID) {
        if let connectedHandler = connectedHandler {
            DispatchQueue.main.async {
                connectedHandler(peer)
            }
        }
    }

    func disconnected(with peer: MCPeerID) {
        if let disconnectedHandler = disconnectedHandler {
            DispatchQueue.main.async {
                disconnectedHandler(peer)
            }
        }
    }

    func received(_ data: Data, from peer: MCPeerID) {
        if let recievedHandler = recievedHandler {
            DispatchQueue.main.async {
                recievedHandler(peer, data)
            }
        }
    }
}
