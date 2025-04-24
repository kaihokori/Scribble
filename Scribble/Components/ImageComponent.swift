//
//  ImageComponent.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI

struct ImageComponent: View {
    enum ImageType: Equatable {
        case asset(name: String)
        case sfSymbol(name: String)
    }
    
    let imageType: ImageType
    let color: Color?

    init(
        imageType: ImageType,
        color: Color? = nil
    ) {
        self.imageType = imageType
        self.color = color
    }

    var body: some View {
        Group {
            switch imageType {
            case .asset(let name):
                Image(name)
                    .resizable()
            case .sfSymbol(let name):
                Image(systemName: name)
                    .resizable()
            }
        }
        .scaledToFit()
        .padding()
        .foregroundStyle(color ?? Color.primary)
    }
}

struct ImageComponent_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ImageComponent(
                imageType: .asset(name: "Logo")
            )
            .previewDisplayName("Image Component (Asset)")
            .previewLayout(.sizeThatFits)
            .frame(maxWidth: 300)
            .background(Color.background)
            
            ImageComponent(
                imageType: .sfSymbol(name: "star.fill"),
                color: Color.accentColor
            )
            .previewDisplayName("Image Component (SF Symbol)")
            .previewLayout(.sizeThatFits)
            .frame(maxWidth: 300)
            .background(Color.background)
        }
    }
}

extension ImageComponent.ImageType {
    var isAsset: Bool {
        if case .asset = self { return true }
        return false
    }
}
