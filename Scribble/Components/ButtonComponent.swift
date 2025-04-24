//
//  ButtonComponent.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI

struct ButtonComponent: View {
    @State private var rotationAngle: Double = 0
    
    let text: String?
    let font: Font
    let symbol: String?
    let isCircular: Bool
    let foregroundColor: Color?
    let backgroundColor: Color?
    let action: () -> Void
    let isEnabled: Bool?
    let isWide: Bool
    let animatedBorder: Bool

    init(
        text: String? = nil,
        font: Font = .title3,
        symbol: String? = nil,
        isCircular: Bool = false,
        foregroundColor: Color? = nil,
        backgroundColor: Color? = nil,
        isEnabled: Bool? = nil,
        isWide: Bool = false,
        animatedBorder: Bool = false,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.font = font
        self.symbol = symbol
        self.isCircular = isCircular
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.action = action
        self.isEnabled = isEnabled
        self.isWide = isWide
        self.animatedBorder = animatedBorder
    }

    var body: some View {
        let enabled = isEnabled ?? true
        let bgColor = enabled ? (backgroundColor ?? Color.background_alt) : Color.gray.opacity(0.3)

        Button(action: {
            if enabled {
                action()
            }
        }) {
            if isCircular, let symbol = symbol {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(enabled ? (foregroundColor ?? Color.white) : Color.gray)
                    .padding()
                    .background(bgColor)
                    .clipShape(Circle())
            } else {
                HStack(alignment: .center) {
                    if let symbol = symbol {
                        Image(systemName: symbol)
                            .font(.title2)
                            .foregroundStyle(enabled ? (foregroundColor ?? Color.white) : Color.gray)
                    }
                    if let text = text {
                        Text(text)
                            .font(font)
                            .bold()
                            .foregroundStyle(enabled ? (foregroundColor ?? Color.white) : Color.gray)
                    }
                }
                .frame(maxWidth: isWide ? .infinity : nil)
                .padding()
                .background(bgColor)
                .cornerRadius(10)
            }
        }
        .disabled(!enabled)
        .onAppear {
            if animatedBorder {
                withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
        }
        .overlay(
            animatedBorder ? animatedBorderView : nil
        )
    }

    private var animatedBorderView: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.clear, lineWidth: 4)
            .overlay(
                AngularGradient(
                    gradient: Gradient(colors: [.clear, .clear, .clear, isEnabled ?? true ? .accentColor : Color.gray.opacity(0.6)]),
                    center: .center,
                    angle: .degrees(rotationAngle)
                )
                .mask(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 4)
                )
            )
            .allowsHitTesting(false)
    }
}

struct ButtonComponent_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ButtonComponent(text: "Reposition", action: {
                print("Text button pressed")
            })
            .previewDisplayName("Button Component")
            .previewLayout(.sizeThatFits)
            .frame(width: 300)
            .background(Color.background)

            ButtonComponent(text: "Reposition", foregroundColor: Color.gray, action: {
                print("Foreground color text button pressed")
            })
            .previewDisplayName("Button Component (Foreground Color)")
            .previewLayout(.sizeThatFits)
            .frame(width: 300)
            .background(Color.background)

            ButtonComponent(text: "Reposition", backgroundColor: Color.blue, action: {
                print("Background color text button pressed")
            })
            .previewDisplayName("Button Component (Background Color)")
            .previewLayout(.sizeThatFits)
            .frame(width: 300)
            .background(Color.background)

            ButtonComponent(text: "Reposition", isWide: true, action: {
                print("Wide text button pressed")
            })
            .previewDisplayName("Button Component (Wide)")
            .previewLayout(.sizeThatFits)
            .frame(width: 300)
            .background(Color.background)

            ButtonComponent(text: "Reposition", symbol: "move.3d", action: {
                print("Text & symbol button pressed")
            })
            .previewDisplayName("Button Component (Text & SF Symbol)")
            .previewLayout(.sizeThatFits)
            .frame(width: 300)
            .background(Color.background)

            ButtonComponent(text: "Reposition", symbol: "move.3d", isEnabled: false, action: {
                print("Text & symbol button pressed")
            })
            .previewDisplayName("Button Component (Text & SF Symbol - Disabled)")
            .previewLayout(.sizeThatFits)
            .frame(width: 300)
            .background(Color.background)

            ButtonComponent(symbol: "move.3d", action: {
                print("Symbol button pressed")
            })
            .previewDisplayName("Button Component (SF Symbol)")
            .previewLayout(.sizeThatFits)
            .frame(width: 300)
            .background(Color.background)

            ButtonComponent(symbol: "move.3d", isCircular: true, animatedBorder: true, action: {
                print("Circular button pressed")
            })
            .previewDisplayName("Button Component (Circular)")
            .previewLayout(.sizeThatFits)
            .frame(width: 300)
            .background(Color.background)

            ButtonComponent(
                text: "Animated Border", animatedBorder: true, action: {
                    print("Animated Border Button pressed")
                }
            )
            .previewDisplayName("Button Component (Animated Border)")
            .previewLayout(.sizeThatFits)
            .frame(width: 300)
            .background(Color.background)
        }
    }
}
