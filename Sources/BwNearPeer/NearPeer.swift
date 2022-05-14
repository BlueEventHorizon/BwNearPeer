//
//  NearPeer.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity

public enum NearPeerDiscoveryInfoKey: String {
    /// Bundle Identifierなどアプリを特定するために使用すると良い
    case identifier

    /// ４桁の数字など、事前に交換した簡易な数字を与えると良い
    case passcode
}

public protocol NearPeerProtocol {

     init(maxPeers: Int)

     func start(serviceName: String, displayName: String, discoveryInfo: [NearPeerDiscoveryInfoKey: String]?)

     func stop()

     func invalidate()

     func stopAdvertising()

     func restartAdvertising()

     func onConnecting(_ handler: ConnectionHandler?)

     func onConnected(_ handler: ConnectionHandler?)

     func onDisconnect(_ handler: ConnectionHandler?)

     func onReceived(_ handler: DataReceiveHandler?)

    // 全てのPeerに送っている。（個別に送れそうですね！！）
     func send(_ data: Data)
}

public class NearPeer: NearPeerProtocol {
    private let maxNumPeers: Int

    private var connection: PeerConnection?
    private var advertiser: PeerAdvertiser?
    private var browser: PeerBrowser?

    // ------------------------------------------------------------------------------------------
    // MARK: - private
    // ------------------------------------------------------------------------------------------

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

    // ------------------------------------------------------------------------------------------
    // MARK: - public
    // ------------------------------------------------------------------------------------------

    required public init(maxPeers: Int) {
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

        self.connection = PeerConnection(displayName: validatedDisplayName)

        guard let connection = connection else { return }

        advertiser = PeerAdvertiser(session: connection.session)
        browser = PeerBrowser(session: connection.session, maxPeers: maxNumPeers)

        advertiser?.start(serviceType: validatedServiceName, discoveryInfo: discoveryInfo)
        browser?.start(serviceType: validatedServiceName, discoveryInfo: discoveryInfo)
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
        self.connection?.connectedHandler = handler
    }

    public func onConnected(_ handler: ConnectionHandler?) {
        self.connection?.connectedHandler = handler
    }

    public func onDisconnect(_ handler: ConnectionHandler?) {
        self.connection?.disconnectedHandler = handler
    }

    public func onReceived(_ handler: DataReceiveHandler?) {
        self.connection?.receivedHandler = handler
    }

    // 全てのPeerに送っている。（個別に送れそうですね！！）
    public func send(_ data: Data) {
        guard let connection = connection else {
            return
        }

        let peers = connection.session.connectedPeers

        guard !peers.isEmpty else {
            return
        }

        do {
            // .reliableではおそらくtcp（相当）を使う。
            try connection.session.send(data, toPeers: peers, with: .reliable)
        } catch {
            print(error.localizedDescription)
        }
    }
}
