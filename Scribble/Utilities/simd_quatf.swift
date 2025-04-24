//
//  simd_quatf.swift
//  Scribble
//
//  Created by Kyle Graham on 21/2/2025.
//

import simd

extension simd_quatf: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let values = try container.decode([Float].self)
        self.init(ix: values[0], iy: values[1], iz: values[2], r: values[3])
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([vector.x, vector.y, vector.z, vector.w])
    }
}
