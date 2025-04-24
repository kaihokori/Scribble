//
//  CreateSelectionView.swift
//  Scribble
//
//  Created by Kyle Graham on 6/1/2025.
//

import SwiftUI

struct CreateSelectionView: View {
    @Binding var navigationPath: NavigationPath
    var storyManager: StoryManager
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    ButtonComponent(text: "Return", foregroundColor: Color.accentColor) {
                        navigationPath.removeLast()
                    }
                    Spacer()
                }
                Spacer()
            }
            
            VStack {
                TextComponent(text: "Create an Object", fontStyle: .largeTitle, isBold: true)
                TextComponent(text: "Select how you'll create this object", fontStyle: .title2)
                Group {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        VStack {
                            inPlaceButton
                            inSpaceButton
                        }
                    } else {
                        HStack {
                            inPlaceButton
                            inSpaceButton
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .background(Color.background)
    }
    
    private var inPlaceButton: some View {
        Button(action: {
            navigationPath.append("Create2DView")
        }) {
            VStack {
                ImageComponent(imageType: .asset(name: "InPlace"))
                    .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 150 : 200, height: UIDevice.current.userInterfaceIdiom == .phone ? 150 : 200)
                TextComponent(text: "In-Place (2D)", fontStyle: .title2)
                    .padding(.top)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 30)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.background_alt)
            )
        }
        .padding()
    }

    private var inSpaceButton: some View {
        Button(action: {
            navigationPath.append("Create3DView")
        }) {
            VStack {
                ImageComponent(imageType: .asset(name: "InSpace"))
                    .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 150 : 200, height: UIDevice.current.userInterfaceIdiom == .phone ? 150 : 200)
                TextComponent(text: "In-Space (3D)", fontStyle: .title2)
                    .padding(.top)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 30)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.background_alt)
            )
        }
        .padding()
    }
}

struct CreateSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSelectionView(navigationPath: .constant(NavigationPath()), storyManager: StoryManager())
            .previewDisplayName("Create Selection View")
            .previewInterfaceOrientation(.landscapeRight)
    }
}
