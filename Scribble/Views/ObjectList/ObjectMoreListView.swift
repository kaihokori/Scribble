//
//  ObjectMoreListView.swift
//  Scribble
//
//  Created by Kyle Graham on 5/1/2025.
//

import SwiftUI

struct ObjectMoreListView: View {
    var onRenameTapped: () -> Void
    var onRepositionTapped: () -> Void
    var onDuplicateTapped: () -> Void
    var onDeleteTapped: () -> Void

    var body: some View {
        VStack {
            VStack {
                ButtonComponent(text: "Rename", font: .body, action: onRenameTapped)
                ButtonComponent(text: "Reposition", font: .body, action: onRepositionTapped)
                ButtonComponent(text: "Duplicate", font: .body, action: onDuplicateTapped)
                ButtonComponent(text: "Delete", font: .body, action: onDeleteTapped)
            }
            .padding(.vertical, 3)
        }
        .background(Color.background_alt)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ObjectMoreListView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectMoreListView(
            onRenameTapped: { print("Rename tapped") },
            onRepositionTapped: { print("Reposition tapped") },
            onDuplicateTapped: { print("Duplicate tapped") },
            onDeleteTapped: { print("Delete tapped") }
        )
        .previewDisplayName("Object More List View")
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.background)
    }
}
