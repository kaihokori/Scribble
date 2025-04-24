//
//  Stroke.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import UIKit

struct Stroke: Codable, Identifiable {
    var id: UUID = UUID()
    var points: [Point]
    var color: CodableColor
    var thickness: CGFloat
}
