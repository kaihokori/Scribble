//
//  Drawing2DStroke.swift
//  Scribble
//
//  Created by Kyle Graham on 4/2/2025.
//

import SwiftUI

struct Drawing2DStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var thickness: CGFloat
}
