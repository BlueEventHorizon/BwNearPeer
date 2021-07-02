//
//  BorderButton.swift
//  CombineExample
//
//  Created by Katsuhiko Terada on 2021/06/07.
//

import SwiftUI

struct BorderedText: View {
    @State var text: String
    @State var selected: Bool = true

    var color: Color = .blue
    var weight: Font.Weight = .bold
    var lineLimit: Int = 3
    var cornerRadius: CGFloat = 10

    var body: some View {
        let bgColor: Color = selected ? .blue : .secondary
        let fgColor: Color = selected ? .white : .white

        Text(text)
            .multilineTextAlignment(.center)
            .lineLimit(lineLimit)
            .font(.system(size: 18.0, weight: weight))
            .padding(10)
            // .padding(.vertical, 10)
            // .padding(.horizontal, 10)
            // .lineSpacing(10.0)
            // .frame(height: height)
            .background(bgColor)
            .foregroundColor(fgColor)
            .cornerRadius(cornerRadius)
            // 角丸ボーダーライン
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(selected ? Color(UIColor.darkGray) : Color(UIColor.systemGray3), lineWidth: 1)
            )
    }
}

struct BorderButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BorderedText(text: "これはテストだよ", selected: true)
            BorderedText(text: "これはテストだよ", selected: false)
        }
    }
}
