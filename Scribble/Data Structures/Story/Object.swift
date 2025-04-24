//
//  Object.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SceneKit

struct Object: Codable {
    var id: UUID = UUID()
    var name: String = ""
    var frames: [Frame]
    var activeFrameIndex: Int = 0
    var playbackSetting: PlaybackSetting
    var direction: Int = 1
    var position: SIMD3<Float>
    var orientation: simd_quatf
}
