//
//  AppState.swift
//  InRoomLogApp
//
//  Created by Katsuhiko Terada on 2022/08/15.
//

import Foundation

final class AppState: ObservableObject {
    enum ViewState {
        case splash
        case main
    }

    @Published private(set) var viewState: ViewState = .splash

    static let `default` = AppState()

    @MainActor
    func setViewState(_ viewState: ViewState) {
        self.viewState = viewState
    }
}
