//
//  TextComponent.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI

struct TextComponent: View {
    let text: String
    let fontStyle: Font
    let isBold: Bool
    let color: Color?
    let multilineTextAlignment: TextAlignment

    init(
        text: String,
        fontStyle: Font = .body,
        isBold: Bool = false,
        color: Color? = nil,
        multilineTextAlignment: TextAlignment = .leading
    ) {
        self.text = text
        self.fontStyle = fontStyle
        self.isBold = isBold
        self.color = color
        self.multilineTextAlignment = multilineTextAlignment
    }

    var body: some View {
        Text(text)
            .font(fontStyle)
            .fontWeight(isBold ? .bold : .regular)
            .foregroundColor(color ?? Color.white)
            .multilineTextAlignment(multilineTextAlignment)
    }
}

struct TextComponent_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TextComponent(
                text: "Cancel",
                fontStyle: .body,
                color: Color.accentColor
            )
            .previewDisplayName("Text Component (Color)")
            .previewLayout(.sizeThatFits)
            .frame(maxWidth: 300)
            .background(Color.background)
            
            TextComponent(
                text: "Before We Begin",
                fontStyle: .title,
                isBold: true
            )
            .previewDisplayName("Text Component (Bold)")
            .previewLayout(.sizeThatFits)
            .frame(maxWidth: 300)
            .background(Color.background)
            
            TextComponent(
                text: "This experience uses augmented reality, so permission to access the camera is needed",
                fontStyle: .title3,
                multilineTextAlignment: .center
            )
            .previewDisplayName("Text Component (Multiline)")
            .previewLayout(.sizeThatFits)
            .frame(maxWidth: 300)
            .background(Color.background)
        }
    }
}
