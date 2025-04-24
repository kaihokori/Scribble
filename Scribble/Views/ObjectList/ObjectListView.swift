//
//  ObjectListView.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI

struct ObjectListView: View {
    @ObservedObject var storyManager: StoryManager
    var onMoreButtonPressed: (Object) -> Void
    var onCreatePressed: () -> Void
    @Binding var selectedObject: Object?

    var body: some View {
        ZStack {
            Color.background_alt

            VStack {
                ScrollView {
                    ForEach(storyManager.story.objects, id: \.id) { object in
                        ObjectListRowView(
                            objectPreview: AnyView(
                                FramePreviewComponent(frame: object.frames[object.activeFrameIndex])
                            ),
                            title: object.name.isEmpty ? "Unnamed Object" : object.name,
                            isSelected: selectedObject?.id == object.id,
                            onMorePressed: {
                                onMoreButtonPressed(object)
                            }
                        )
                    }
                }
                .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 250 : 300)
                .scrollIndicators(.hidden)

                Button(action: {
                    onCreatePressed()
                }) {
                    Text("Create")
                        .font(.title3)
                        .bold()
                        .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 200 : 250)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.background)
                        .cornerRadius(10)
                }
            }
            .padding()
            .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 270 : 320)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ObjectListView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectListView(
            storyManager: StoryManager(),
            onMoreButtonPressed: { _ in },
            onCreatePressed: {},
            selectedObject: .constant(nil)
        )
        .previewDisplayName("Object List View")
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.background)
    }
}
