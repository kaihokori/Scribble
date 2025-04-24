//
//  HelpItem.swift
//  Scribble
//
//  Created by Kyle Graham on 21/2/2025.
//

import Foundation

struct HelpItem: Identifiable {
    let id = UUID()
    let symbol: String
    let heading: String
    let body: String
}
