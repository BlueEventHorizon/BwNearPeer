//
//  NearPeerLogger.swift
//  Toolsモジュール用のロガー定義
//
//  Created by k2moons on 2025/05/14
//

import Foundation
import OSLog

/// BwNearPeerモジュール全体で使用するデフォルトのロガーインスタンス
/// - Note: このロガーを使用することで、BwNearPeerモジュールからのログを一貫して識別できます
let logger = Logger.default(category: "BwNearPeer")

