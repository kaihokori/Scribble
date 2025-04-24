//
//  SlideView.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI

struct SlideView: View {
    let slide: OnboardingSlide
    let isLastSlide: Bool
    let onNext: () -> Void

    var body: some View {
        VStack() {
            Spacer()
            
            ImageComponent(imageType: slide.image, color: slide.color)
                .frame(
                    width: UIDevice.current.userInterfaceIdiom == .phone
                        ? (slide.image.isAsset ? UIScreen.main.bounds.width * 0.8 : UIScreen.main.bounds.width * 0.5)
                        : (slide.image.isAsset ? 700 : 350)
                )
                .padding(.bottom, 30)

            Text(slide.heading)
                .font(.largeTitle)
                .bold()
                .foregroundStyle(Color.white)

            Text(slide.subheading)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(Color.white)
                .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? UIScreen.main.bounds.width * 0.8 : 500)

            Spacer()
            
            ButtonComponent(text: slide.buttonText, foregroundColor: Color.accentColor, isWide: true, action: onNext)
            .frame(width: UIScreen.main.bounds.width * 0.4)
        }
        .padding()
        .background(Color.background)
    }
}

struct SlideView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SlideView(
                slide: OnboardingSlide(
                    image: .asset(name: "Logo"),
                    heading: "Welcome!",
                    subheading: "Discover a new way to express your story",
                    buttonText: "Next"
                ),
                isLastSlide: false,
                onNext: { print("Next tapped") }
            )
            .previewDisplayName("Slide View (Image)")
            .previewInterfaceOrientation(.landscapeRight)
            .previewLayout(.sizeThatFits)

            SlideView(
                slide: OnboardingSlide(
                    image: .sfSymbol(name: "arkit"),
                    heading: "Before We Begin",
                    subheading: "This experience uses augmented reality, so permission to access the camera is needed",
                    buttonText: "Grant Permission",
                    color: Color.accentColor
                ),
                isLastSlide: false,
                onNext: { print("Next tapped") }
            )
            .previewDisplayName("Slide View (SF Symbol)")
            .previewInterfaceOrientation(.landscapeRight)
            .previewLayout(.sizeThatFits)
        }
    }
}
