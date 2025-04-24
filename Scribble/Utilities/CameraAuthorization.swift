//
//  CameraAuthorization.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import AVFoundation

struct CameraAuthorization {
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)

            var isAuthorized = status == .authorized

            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }

            return isAuthorized
        }
    }
}
