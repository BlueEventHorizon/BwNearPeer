//
//  PearConnection.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import MultipeerConnectivity

public typealias ConnectionHandler = (_ peerID: MCPeerID) -> Void
public typealias DataReceiveHandler = (_ peerID: MCPeerID, _ data: Data?) -> Void

class PeerConnection: NSObject, MCSessionDelegate {
    private(set) var peerID: MCPeerID
    private(set) var session: MCSession
    private(set) var state: MCSessionState = .notConnected

    var connectingHandler: ConnectionHandler?
    var connectedHandler: ConnectionHandler?
    var disconnectedHandler: ConnectionHandler?
    var receivedHandler: DataReceiveHandler?

    init(displayName: String = "unknown") {

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
        receivedHandler?( peerID, data)
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
            connectingHandler?(peerID)

            case .connected:
                // called after certificated
            connectedHandler?(peerID)

            case .notConnected:
            disconnectedHandler?(peerID)

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
