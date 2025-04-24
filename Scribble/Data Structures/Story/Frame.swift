//
//  Frame.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import Foundation

struct Frame: Codable {
    var id: UUID = UUID()
    var strokes: [Stroke]
}
