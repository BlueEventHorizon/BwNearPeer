//
//  AppDelegate.swift
//  InRoomLogMonitor
//
//  Created by Katsuhiko Terada on 2022/10/26.
//

import Foundation
import SwiftUI

#if canImport(Cocoa)

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {

    }

    func applicationWillTerminate(_ notification: Notification) {

    }
}

#else

class AppDelegate: UIResponder, UIApplicationDelegate {
    // swiftlint:disable:next discouraged_optional_collection
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }
}

#endif
