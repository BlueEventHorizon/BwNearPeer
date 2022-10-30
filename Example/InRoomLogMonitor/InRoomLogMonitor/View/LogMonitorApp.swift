//
//  LogMonitorApp.swift
//  InRoomLogMonitor
//
//  Created by Katsuhiko Terada on 2022/10/26.
//

import SwiftUI
import InRoomLogger

@main
struct LogMonitorApp: App {

// @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var monitor: InRoomLogMonitor = InRoomLogMonitor()
    @StateObject private var appState = AppState.default

    var body: some Scene {
        WindowGroup {
            switch appState.viewState {
                case .splash:
                    SplashView()
                        .frame(width: 400, height: 300)
                        .environmentObject(appState)

                case .main:
                    LogMonitorMainView()
                        .frame(minWidth: 400, minHeight: 300)
                        .onAppear {
                            monitor.start()
                        }
                        .environmentObject(monitor)
            }
        }
    }
}

