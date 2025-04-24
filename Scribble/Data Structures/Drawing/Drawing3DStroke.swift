//
//  Drawing3DStroke.swift
//  Scribble
//
//  Created by Kyle Graham on 8/2/2025.
//

import SwiftUI
import SceneKit

struct Drawing3DStroke: Identifiable {
    let id = UUID()
    var points: [SCNVector3]
    var color: Color
    var thickness: CGFloat
}
