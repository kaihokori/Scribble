//
//  Story.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import Foundation

struct Story: Codable {
    var id: UUID = UUID()
    var title: String
    var objects: [Object]
}
