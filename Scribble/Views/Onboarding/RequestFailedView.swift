//
//  RequestFailedView.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI

struct RequestFailedView: View {
    var body: some View {
        VStack() {
            Spacer()
            
            ImageComponent(imageType: .sfSymbol(name: "exclamationmark.triangle"), color: Color.highlight)
                .frame(height: 200)
                .padding(.bottom, 30)

            TextComponent(text: "Something Went Wrong", fontStyle: .largeTitle, isBold: true)

            TextComponent(text: "It appears permission wasn’t given. To continue, you'll need to provide this through your device's settings", fontStyle: .title3, multilineTextAlignment: .center)
                .padding(.horizontal)
                .frame(width: 500)

            Spacer()
            
            ButtonComponent(text: "Go to Settings", foregroundColor: Color.accentColor, isWide: true, action: openAppSettings)
            .padding(.bottom, 40)
            .frame(width: UIScreen.main.bounds.width * 0.3)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.background)
    }

    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL, options: [:]) { success in
                if !success {
                    print("Failed to open app settings.")
                }
            }
        }
    }
}

struct RequestFailedView_Previews: PreviewProvider {
    static var previews: some View {
        RequestFailedView()
            .previewDisplayName("Request Failed View")
            .previewInterfaceOrientation(.landscapeRight)
    }
}
