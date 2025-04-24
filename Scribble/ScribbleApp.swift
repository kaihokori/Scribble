//
//  ScribbleApp.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI

@main
struct ScribbleApp: App {
    init() {
        UIPageControl.appearance().overrideUserInterfaceStyle = .dark
        UserDefaults.standard.register(defaults: [
            "showGrid2D": true,
            "gridSpacing2D": 70.0,
            "strokeResolution2D": 35.0,
            "isSnapping3D": false,
            "snapDistance3D": 0.026,
            "drawingDistance3D": 0.23,
            "showStoryHelp": true,
            "show2DHelp": true,
            "show3DHelp": true,
            "animateObjectsButton": true
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                StoryView()
            } else {
                OnboardingView()
            }
        }
    }
}
