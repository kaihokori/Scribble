//
//  ColorPickerComponent.swift
//  Scribble
//
//  Created by Kyle Graham on 4/2/2025.
//

import SwiftUI

struct ColorPickerComponent: View {
    @Binding var selectedColor: Color
    @Binding var selectedThickness: CGFloat
    @State var colors: [ColorPicker] = [
        ColorPicker(color: .red),
        ColorPicker(color: .purple),
        ColorPicker(color: .pink),
        ColorPicker(color: .blue),
        ColorPicker(color: .orange),
        ColorPicker(color: .green),
        ColorPicker(color: .yellow),
        ColorPicker(color: .mint),
        ColorPicker(color: .gray),
        ColorPicker(color: .white),
        ColorPicker(color: .brown),
        ColorPicker(color: .black)
    ]

    init(selectedColor: Binding<Color>, selectedThickness: Binding<CGFloat>) {
        _selectedColor = selectedColor
        _selectedThickness = selectedThickness
    }

    var body: some View {
        HStack {
            VStack {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: selectedThickness)
                    .foregroundColor(selectedColor)
                    .padding(.trailing, 2)
            }
            .frame(width: 70, height: 80)

            LazyHGrid(
                rows: Array(
                    repeating: GridItem(spacing: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 0),
                    count: UIDevice.current.userInterfaceIdiom == .phone ? 3 : 2
                )
            ) {
                ForEach(colors) { color in
                    Circle()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(color.color)
                        .opacity(0.8)
                        .scaleEffect(selectedColor == color.color ? 0.7 : 1)
                        .overlay {
                            Circle()
                                .stroke(lineWidth: 3)
                                .foregroundColor(selectedColor == color.color ? .white : .clear)
                        }
                        .onTapGesture {
                            withAnimation {
                                selectedColor = color.color
                            }
                        }
                }
            }
            .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 150 : 100)

            VSlider(value: $selectedThickness, in: 10...50, step: 10)
                .frame(width: 30, height: 82)
                .padding(.horizontal)
        }
        .padding()
        .background(Color.background_alt, in: RoundedRectangle(cornerRadius: 20))
        .frame(height: 100)
    }
}

struct ColorPickerComponent_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerComponent(selectedColor: .constant(.pink), selectedThickness: .constant(5))
            .previewDisplayName("Color Picker Component")
            .previewLayout(.sizeThatFits)
            .background(Color.background)
    }
}

