//
//  CreateSettings2DView.swift
//  Scribble
//
//  Created by Kyle Graham on 5/2/2025.
//

import SwiftUI

struct CreateSettings2DView: View {
    @Binding var showGrid: Bool
    @Binding var gridSpacing: CGFloat
    @Binding var strokeResolution: Double

    var body: some View {
        VStack {
            HStack {
                TextComponent(text: "Grid", fontStyle: .title3)
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $showGrid)
                    .labelsHidden()
                    .onChange(of: showGrid) {
                        UserDefaults.standard.set(showGrid, forKey: "showGrid2D")
                    }
            }
            HStack {
                TextComponent(text: "Grid Size", fontStyle: .title3)
                    .foregroundColor(.white)
                Spacer()
                Slider(value: $gridSpacing, in: 20...140, step: 1)
                    .disabled(!showGrid)
                    .frame(width: 150)
                    .onChange(of: gridSpacing) {
                        UserDefaults.standard.set(Double(gridSpacing), forKey: "gridSpacing2D")
                    }
            }
            HStack {
                TextComponent(text: "Stroke Resolution", fontStyle: .title3)
                    .foregroundColor(.white)
                Spacer()
                Slider(value: $strokeResolution, in: 5...100, step: 1)
                    .frame(width: 150)
                    .onChange(of: strokeResolution) {
                        UserDefaults.standard.set(strokeResolution, forKey: "strokeResolution2D")
                    }
            }
        }
        .padding()
        .background(Color.background_alt)
        .frame(width: 350)
        .cornerRadius(10)
    }
}

struct CreateSettings2DView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSettings2DView(
            showGrid: .constant(true),
            gridSpacing: .constant(50),
            strokeResolution: .constant(25)
        )
        .previewDisplayName("Create 2D Settings View")
        .previewLayout(.sizeThatFits)
        .background(Color.background)
    }
}

