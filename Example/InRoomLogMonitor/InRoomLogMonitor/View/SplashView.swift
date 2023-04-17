//
//  SplashView.swift
//  InRoomLogMonitor
//
//  Created by Katsuhiko Terada on 2022/08/15.
//

import Foundation
import SwiftUI

struct SplashView: View {
    @StateObject var viewModel: SplashViewModel = .init()

    var body: some View {
        VStack {
            Text("ログモニター".decorate("ログ"))
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.start()
        }
    }
}

final class SplashViewModel: ObservableObject {
    func start() {
        Task {
            try? await Task.sleep(nanoseconds: TimeValueObject(seconds: 1.0).nanoseconds)

            await AppState.default.setViewState(.main)
        }
    }
}
