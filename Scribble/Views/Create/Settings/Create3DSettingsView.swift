//
//  CreateSettings3DView.swift
//  Scribble
//
//  Created by Kyle Graham on 10/2/2025.
//

import SwiftUI

struct CreateSettings3DView: View {
    @Binding var isSnapping: Bool
    @Binding var snapDistance: Float
    @Binding var drawingDistance: Float

    var body: some View {
        VStack {
            HStack {
                TextComponent(text: "Snapping", fontStyle: .title3)
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $isSnapping)
                    .labelsHidden()
                    .onChange(of: isSnapping) {
                        UserDefaults.standard.set(isSnapping, forKey: "isSnapping3D")
                    }
            }
            
            HStack {
                TextComponent(text: "Snap Distance", fontStyle: .title3)
                    .foregroundColor(.white)
                Spacer()
                Slider(value: $snapDistance, in: 0.01...0.05, step: 0.004)
                    .frame(width: 150)
                    .disabled(!isSnapping)
                    .onChange(of: snapDistance) {
                        UserDefaults.standard.set(Double(snapDistance), forKey: "snapDistance3D")
                    }
            }
            
            HStack {
                TextComponent(text: "Drawing Distance", fontStyle: .title3)
                    .foregroundColor(.white)
                Spacer()
                Slider(value: $drawingDistance, in: 0.05...0.5, step: 0.045)
                    .frame(width: 150)
                    .onChange(of: drawingDistance) {
                        UserDefaults.standard.set(Double(drawingDistance), forKey: "drawingDistance3D")
                    }
            }
        }
        .padding()
        .background(Color.background_alt)
        .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 300 : 400)
        .cornerRadius(10)
    }
}

struct CreateSettings3DView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSettings3DView(
            isSnapping: .constant(true),
            snapDistance: .constant(0.3),
            drawingDistance: .constant(0.1)
        )
        .previewDisplayName("Create 3D Settings View")
        .previewLayout(.sizeThatFits)
        .background(Color.background)
    }
}

