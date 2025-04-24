//
//  OnboardingSlide.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUICore

struct OnboardingSlide {
    let image: ImageComponent.ImageType
    let heading: String
    let subheading: String
    let buttonText: String
    let color: Color

    init(image: ImageComponent.ImageType, heading: String, subheading: String, buttonText: String, color: Color = Color.accentColor) {
        self.image = image
        self.heading = heading
        self.subheading = subheading
        self.buttonText = buttonText
        self.color = color
    }
}
