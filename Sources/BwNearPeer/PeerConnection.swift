//
//  PearConnection.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity

protocol PeerConnectionDependency {
    func connecting(with peer: MCPeerID)
    func connected(with peer: MCPeerID)
    func disconnected(with peer: MCPeerID)
    func received(_ data: Data, from peer: MCPeerID)

    func stopAdvertising()
    func restartAdvertising()
}

class PeerConnection: NSObject, MCSessionDelegate {
    private let dependency: PeerConnectionDependency

    private(set) var peerID: MCPeerID
    private(set) var session: MCSession
    private(set) var state: MCSessionState = .notConnected

    init(displayName: String = "unknown", dependency: PeerConnectionDependency) {
        self.dependency = dependency
        self.peerID = MCPeerID(displayName: String(displayName.prefix(63)))
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)

        super.init()

        self.session.delegate = self
    }

    func disconnect() {
        session.delegate = nil
        session.disconnect()
    }

    // ------------------------------------------------------------------------------------------
    // MARK: - MCSessionDelegate
    // ------------------------------------------------------------------------------------------

    // Indicates that an NSData object has been received from a nearby peer. Required.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        dependency.received(data, from: peerID)
    }

    // Indicates that the local peer began receiving a resource from a nearby peer. Required.
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // TODO:
    }

    // Indicates that the local peer finished receiving a resource from a nearby peer. Required.
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // TODO:
    }

    // Called when a nearby peer opens a byte stream connection to the local peer. Required.
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // TODO:
    }

    // Called when the state of a nearby peer changes. Required.
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
            case .connecting:
                dependency.connecting(with: peerID)

            case .connected:
                // called after certificated
                dependency.connected(with: peerID)

                if self.state != .connected {
                    // called n times when MCSession has n connected peers
                    // dependency.stopAdvertising()
                }

            case .notConnected:
                dependency.disconnected(with: peerID)

                if self.state == .connected {
                    // restart when something wrong
                    // dependency.restartAdvertising()
                }

            default:
                break
        }
        self.state = state
    }

    // Called to validate the client certificate provided by a peer when the connection is first established.
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}
