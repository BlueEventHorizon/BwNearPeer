//
//  String+decorate.swift
//  InRoomLogMonitor
//
//  Created by Katsuhiko Terada on 2022/08/15.
//

import Foundation

extension String {
    func decorate(_ target: String) -> AttributedString {
        var attributedString = AttributedString(self)

        if let range = attributedString.range(of: target) {
            attributedString[range].foregroundColor = .red
            attributedString[range].font = .system(size: 17, weight: .bold)
        }
        return attributedString
    }
}
