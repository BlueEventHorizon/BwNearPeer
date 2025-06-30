//
//  Logger.swift
//  アプリケーションのログ機能を拡張するユーティリティ
//
//  Created by k2moons on 2025/05/14
//

import Foundation
import OSLog

/// OSLogのLoggerクラスに便利な機能を追加する拡張
public extension Logger {
    /// デフォルトのロガーを生成するファクトリメソッド
    /// - Parameter category: ログのカテゴリ（ログの分類に使用）
    /// - Returns: 設定済みのLoggerインスタンス
    /// - Note: subsystemにはアプリのバンドルIDが自動的に使用される
    static func `default`(category: String) -> Self {
        let subsystem = "beowulf-tech.com"
        return os.Logger(subsystem: subsystem, category: category)
    }

    /// 現在の実行スレッド名を取得するプロパティ
    /// - Returns: 実行スレッドの識別名（mainスレッド、名前付きスレッド、ディスパッチキュー名など）
    /// - Note: ログにスレッド情報を付加する際に使用できる
    var thread: String {
        if Thread.isMainThread {
            return "main"
        }
        if let threadName = Thread.current.name, !threadName.isEmpty {
            return threadName
        }
        if let threadName = String(validatingUTF8: __dispatch_queue_get_label(nil)), !threadName.isEmpty {
            return threadName
        }
        return Thread.current.description
    }

    var className: String {
        String(describing: type(of: self))
    }
}

/// 使用例：
/// ```swift
/// // カテゴリ「Data」のロガーを作成
/// let logger = Logger.default(category: "Data")
///
/// // 現在のスレッド情報を含めたデバッグログを出力
/// logger.debug("処理を開始しました [\(logger.thread)]")
/// ```
