//
//  CreatePlaybackSettingsView.swift
//  Scribble
//
//  Created by Kyle Graham on 8/2/2025.
//

import SwiftUI

struct CreatePlaybackSettingsView: View {
    @Binding var playbackSetting: PlaybackSetting

    var body: some View {
        VStack {
            playbackOptionView(title: "Loop", setting: .loop)
            playbackOptionView(title: "Bounce", setting: .bounce)
            playbackOptionView(title: "Random", setting: .random)
        }
        .padding()
        .background(Color.background_alt)
        .frame(width: 250)
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private func playbackOptionView(title: String, setting: PlaybackSetting) -> some View {
        HStack {
            Button(action: {
                playbackSetting = setting
            }) {
                TextComponent(text: title, fontStyle: .title3)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: playbackSetting == setting ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(Color.white)
            }
        }
        .padding(.vertical, 2)
    }
}

struct CreatePlaybackSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePlaybackSettingsView(playbackSetting: .constant(.loop))
        .previewDisplayName("Create Playback Settings View")
        .previewLayout(.sizeThatFits)
        .background(Color.background)
    }
}

