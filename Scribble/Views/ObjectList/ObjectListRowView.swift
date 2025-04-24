//
//  ObjectListRowView.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI

struct ObjectListRowView: View {
    var objectPreview: AnyView
    var title: String
    var isSelected: Bool
    var onMorePressed: () -> Void

    var body: some View {
        HStack {
            objectPreview
                .frame(width: 80, height: 50)

            TextComponent(text: title, fontStyle: .title3)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Button(action: onMorePressed) {
                Image(systemName: isSelected ? "ellipsis.circle.fill" : "ellipsis.circle")
                    .font(.title2)
                    .foregroundStyle(Color.white)
            }
            .padding(.trailing)
        }
    }
}

struct ObjectListRowView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectListRowView(
            objectPreview: AnyView(Rectangle().fill(Color.gray)),
            title: "Sample Object",
            isSelected: false,
            onMorePressed: {}
        )
        .previewDisplayName("Object List Row View")
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.background)
    }
}
