//
//  CGPoint.swift
//  Scribble
//
//  Created by Kyle Graham on 4/2/2025.
//

import Foundation

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
