//
//  NearPeer.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity

// 文字列を使用するために、ここでenum定義をしておく
public enum NearPeerDiscoveryInfoKey: String {
    /// Bundle Identifierなどアプリを特定するために使用すると良い
    case identifier

    /// ４桁の数字など、事前に交換した簡易な数字を与えると良い
    case passcode
}

public protocol NearPeerProtocol {
    init(maxPeers: Int)

    func start(serviceType: String, displayName: String, myDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]?, targetDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]?)

    func stop()

    func resume()

    func suspend()

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

    private var connectingHandler: ConnectionHandler?
    private var connectedHandler: ConnectionHandler?
    private var disconnectedHandler: ConnectionHandler?
    private var receivedHandler: DataReceiveHandler?

    // ------------------------------------------------------------------------------------------
    // MARK: - private
    // ------------------------------------------------------------------------------------------

    /// validate
    /// - Parameter service: Must be 1–15 characters long,
    ///                  Can contain only ASCII lowercase letters,
    ///                  numbers, and hyphens, Must contain at least one ASCII letter,
    ///                  Must not begin or end with a hyphen,
    /// - Returns: validated service name
    private func validateServiceType(_ serviceType: String) -> String {
        guard serviceType.count > 0 else {
            return "."
        }

        if serviceType.count > 15 {
            assertionFailure("serviceTypeは、15文字までです \(serviceType)")
        }

        // Must be 1–15 characters long の他は未実装

        return serviceType
    }

    /// 表示名
    /// - Parameter displayName: The maximum allowable length is 63 bytes in UTF-8 encoding
    /// - Returns: validated displayName
    private func validateDisplayName(_ displayName: String) -> String {
        if displayName.isEmpty {
            return "no name"
        }

        if displayName.count > 63 {
            assertionFailure("serviceTypeは、63文字までです: \(displayName)")
        }

        return displayName
    }

    // ------------------------------------------------------------------------------------------
    // MARK: - public
    // ------------------------------------------------------------------------------------------

    public required init(maxPeers: Int) {
        maxNumPeers = maxPeers
    }

    /// Start peer communication
    /// - Parameters:
    ///   - serviceType: サービスタイプ
    ///   - displayName: ローカルピアの表示名
    ///   - discoveryInfo: discoveryInfoパラメータは、ブラウザが見ることができるように広告される文字列キー/値ペアの辞書です。
    ///                    discoveryInfoのコンテンツはBonjour TXTレコード内でアドバタイズされるので、ディスカバリーのパフォーマンスを上げるために辞書を小さくしておく必要があります。
    public func start(serviceType: String, displayName: String, myDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? = nil, targetDiscoveryInfo: [NearPeerDiscoveryInfoKey: String]? = nil) {
        let validatedServiceName = validateServiceType(serviceType)
        let validatedDisplayName = validateDisplayName(displayName)

        self.connection = PeerConnection(displayName: validatedDisplayName)

        guard let connection = connection else { return }

        self.connection?.connectedHandler = connectingHandler
        self.connection?.connectedHandler = connectedHandler
        self.connection?.disconnectedHandler = disconnectedHandler
        self.connection?.receivedHandler = receivedHandler

        advertiser = PeerAdvertiser(session: connection.session)
        browser = PeerBrowser(session: connection.session, maxPeers: maxNumPeers)

        advertiser?.start(serviceType: validatedServiceName, discoveryInfo: myDiscoveryInfo)
        if let targetDiscoveryInfo = targetDiscoveryInfo {
            browser?.start(serviceType: validatedServiceName, discoveryInfo: targetDiscoveryInfo)
        } else {
            browser?.start(serviceType: validatedServiceName, discoveryInfo: myDiscoveryInfo)
        }
    }

    public func stop() {
        advertiser?.stop()
        browser?.stop()
        connection?.disconnect()
    }

    public func resume() {
        advertiser?.resume()
        browser?.resume()
    }

    public func suspend() {
        advertiser?.suspend()
        browser?.suspend()

        connection?.disconnect()
    }

    public func onConnecting(_ handler: ConnectionHandler?) {
        if let connection = self.connection {
            connection.connectingHandler = handler
        } else {
            connectingHandler = handler
        }
    }

    public func onConnected(_ handler: ConnectionHandler?) {
        if let connection = self.connection {
            connection.connectedHandler = handler
        } else {
            connectedHandler = handler
        }
    }

    public func onDisconnect(_ handler: ConnectionHandler?) {
        if let connection = self.connection {
            connection.disconnectedHandler = handler
        } else {
            disconnectedHandler = handler
        }
    }

    public func onReceived(_ handler: DataReceiveHandler?) {
        if let connection = self.connection {
            connection.receivedHandler = handler
        } else {
            receivedHandler = handler
        }
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
