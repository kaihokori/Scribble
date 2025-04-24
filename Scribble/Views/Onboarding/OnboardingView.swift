//
//  OnboardingView.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentIndex = 0
    @State private var showStoryView = false
    @State private var showRequestFailed = false
    private let cameraAuthorization = CameraAuthorization()

    let slides = [
        OnboardingSlide(
            image: .asset(name: "Logo"),
            heading: "Welcome to Scribble!",
            subheading: "Create and share animated room-sized stories",
            buttonText: "Next"
        ),
        OnboardingSlide(
            image: .asset(name: "Draw"),
            heading: "Draw in Unique Ways",
            subheading: "Add 3D objects by drawing on a canvas or in space using your iPad as a brush",
            buttonText: "Next"
        ),
        OnboardingSlide(
            image: .asset(name: "Animate"),
            heading: "Breath Life into your Creations",
            subheading: "Introduce flip book-style animations to your objects with different playback styles and speeds",
            buttonText: "Next"
        ),
        OnboardingSlide(
            image: .asset(name: "Share"),
            heading: "Share your Story",
            subheading: "Export your work as an AR experience and share through your favourite apps",
            buttonText: "Next"
        ),
        OnboardingSlide(
            image: .sfSymbol(name: "arkit"),
            heading: "Let's Get Started!",
            subheading: "This experience uses augmented reality, so you'll be asked for permission to access the camera",
            buttonText: "Launch Demo",
            color: Color.accentColor
        )
    ]

    var body: some View {
        VStack {
            TabView(selection: $currentIndex) {
                ForEach(0..<slides.count, id: \.self) { index in
                    SlideView(slide: slides[index], isLastSlide: index == slides.count - 1, onNext: {
                        handleSlideTransition(index: index)
                    })
                    .tag(index)
                    .padding(.bottom, 40)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .animation(.easeInOut, value: currentIndex)
        }
        .background(Color.background)
        .fullScreenCover(isPresented: $showStoryView) {
            StoryView()
        }
        .fullScreenCover(isPresented: $showRequestFailed) {
            RequestFailedView()
        }
    }

    func handleSlideTransition(index: Int) {
        if index < slides.count - 1 {
            currentIndex += 1
        } else if index == slides.count - 1 {
            requestCameraAccess()
        }
    }

    func requestCameraAccess() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "0" {
            print("Currently running in an Xcode preview, so won't do anything")
            return
        }
        
        Task {
            if await cameraAuthorization.isAuthorized {
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                showStoryView = true
            } else {
                showRequestFailed = true
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .previewDisplayName("Onboarding View")
            .previewInterfaceOrientation(.landscapeRight)
    }
}

