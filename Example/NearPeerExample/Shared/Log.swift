//
//  Log.swift
//  BwNearPeer
//
//  Created by k2moons on 2021/06/26.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import BwLogger
import Foundation
import os

#if targetEnvironment(simulator)
    // swiftlint:disable:next file_types_order prefixed_toplevel_constant
    internal let log = Logger([PrintLogger()], levels: nil)
#else
    // swiftlint:disable:next file_types_order prefixed_toplevel_constant
    internal let log = Logger([OsLogger(subsystem: "beowulf-tech.BwNearPeer.Example", category: "BwTools")], levels: nil)
#endif
