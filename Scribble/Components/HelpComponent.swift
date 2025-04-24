//
//  HelpComponent.swift
//  Scribble
//
//  Created by Kyle Graham on 21/2/2025.
//

import SwiftUI

struct HelpComponent: View {
    let title: String
    let helpItems: [HelpItem]
    let dismissAction: () -> Void

    var body: some View {
        VStack() {
            TextComponent(text: title, fontStyle: .largeTitle, isBold: true, multilineTextAlignment: .center)
                .padding()

            ScrollView {
                ForEach(helpItems) { item in
                    HelpItemView(item: item)
                }
            }

            Spacer()

            ButtonComponent(text: "Close", font: .headline, foregroundColor: Color.accentColor, isWide: true) {
                dismissAction()
            }
            .padding()
        }
        .padding()
        .background(Color.background)
    }
}

struct HelpComponent_Previews: PreviewProvider {
    static var previews: some View {
        HelpComponent(
            title: "Help & Support",
            helpItems: [
                HelpItem(symbol: "pencil.and.scribble", heading: "Draw", body: "Sketch out your creation while adjusting each strokes colour and thickness"),
                HelpItem(symbol: "rectangle.portrait.arrowtriangle.2.outward", heading: "Animate", body: "Create multiple frames, adjust the playback settings and watch it move in real-time"),
                HelpItem(symbol: "beziercurve", heading: "Resolution", body: "Adjust how many nodes (turns) your object will have after being placed in the story"),
                HelpItem(symbol: "hand.tap", heading: "Organise", body: "Tap a selected frame to move it left and right, duplicate or delete it")
            ],
            dismissAction: {
                print("Close button tapped (Preview)")
            }
        )
        .previewLayout(.sizeThatFits)
    }
}
