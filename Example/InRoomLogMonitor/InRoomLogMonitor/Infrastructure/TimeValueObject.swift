//
//  TimeValueObject.swift
//  InRoomLogMonitor
//
//  Created by Katsuhiko Terada on 2022/08/15.
//

import Foundation

struct TimeValueObject {
    private(set) var nanoseconds: UInt64
    var seconds: Float {
        // TODO: 誤差ありすぎ
        Float(nanoseconds) / 1_000_000_000
    }

    init(nanoseconds: UInt64) {
        self.nanoseconds = nanoseconds
    }

    init(seconds: Float) {
        nanoseconds = UInt64(seconds * 1_000_000_000)
    }
}
