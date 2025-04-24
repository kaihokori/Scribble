//
//  HelpItemView.swift
//  Scribble
//
//  Created by Kyle Graham on 21/2/2025.
//

import SwiftUI

struct HelpItemView: View {
    let item: HelpItem

    var body: some View {
        HStack() {
            ImageComponent(imageType: .sfSymbol(name: item.symbol), color: Color.white)
                .frame(width: 80)

            VStack(alignment: .leading) {
                TextComponent(text: item.heading, fontStyle: .title2, isBold: true)

                TextComponent(text: item.body, fontStyle: .headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
}

struct HelpItemView_Previews: PreviewProvider {
    static var previews: some View {
        HelpItemView(item: HelpItem(
            symbol: "pencil.and.scribble",
            heading: "Draw",
            body: "Sketch out your creation while adjusting each strokes colour and thickness"
        ))
        .previewLayout(.sizeThatFits)
        .background(Color.background)
        .padding()
    }
}
