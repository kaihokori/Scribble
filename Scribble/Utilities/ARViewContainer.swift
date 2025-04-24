//
//  ARViewContainer.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI
import ARKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var storyManager: StoryManager
    @Binding var isRepositioning: Bool

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        arView.scene = SCNScene()

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(ARCoordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)

        context.coordinator.setupARSession(for: arView)
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.isRepositioning = isRepositioning
        context.coordinator.updateScene()
    }

    func makeCoordinator() -> ARCoordinator {
        ARCoordinator(storyManager: storyManager)
    }

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: ARCoordinator) {
        uiView.session.pause()
    }
}
