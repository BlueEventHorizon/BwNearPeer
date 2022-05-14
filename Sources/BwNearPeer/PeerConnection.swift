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

    /// 近くのPeerから NSData オブジェクトを受信したことを示す。必須。
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.receivedHandler?( peerID, data)
        }
    }

    /// ローカルPeerが近くのPeerからリソースの受信を開始したことを示す。必須。
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // TODO:
    }

    /// ローカルPeerが近くのPeerからリソースの受信を終了したことを示す。必須。
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // TODO:
    }

    /// 近くのピアからローカルピアへのバイトストリーム接続が開かれたときに呼び出されます。必須。
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // TODO:
    }

    /// 近くのピアの状態が変化したときに呼び出されます。必須。
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
            case .connecting:
            DispatchQueue.main.async {
                self.connectingHandler?(peerID)
            }

            case .connected:
                // called after certificated
            DispatchQueue.main.async {
                self.connectedHandler?(peerID)
            }

            case .notConnected:
            DispatchQueue.main.async {
                self.disconnectedHandler?(peerID)
            }

            default:
                break
        }
        self.state = state
    }

    /// 接続が最初に確立されたときに、相手から提供されたクライアント証明書を検証するために呼び出されます。
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}
