//
//  CreateARViewContainer.swift
//  Scribble
//
//  Created by Kyle Graham on 31/1/2025.
//

import SwiftUI
import ARKit
import SceneKit

struct CreateARViewContainer: UIViewRepresentable {
    @Binding var selectedColor: Color
    @Binding var selectedThickness: CGFloat
    @Binding var isDrawing: Bool
    @ObservedObject var arCoordinator: CreateARCoordinator

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.updateColor(selectedColor)
        context.coordinator.updateThickness(selectedThickness)

        if isDrawing {
            context.coordinator.startDrawing(in: uiView)
        } else {
            context.coordinator.stopDrawing()
        }
    }

    func makeCoordinator() -> CreateARCoordinator {
        return arCoordinator
    }
}
