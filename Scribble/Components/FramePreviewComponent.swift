//
//  FramePreviewComponent.swift
//  Scribble
//
//  Created by Kyle Graham on 5/1/2025.
//

import SwiftUI

struct FramePreviewComponent: View {
    var frame: Frame?
    var background: Color = .background

    var body: some View {
        ZStack {
            if let frame = frame, !frame.strokes.isEmpty {
                Canvas { context, size in
                    guard let (offset, scale) = calculateTransform(for: frame, in: size) else { return }

                    for stroke in frame.strokes {
                        var path = Path()

                        let transformedPoints = stroke.points.map { point in
                            CGPoint(
                                x: (point.x * scale) + offset.x,
                                y: size.height - ((point.y * scale) + offset.y)
                            )
                        }

                        guard let firstPoint = transformedPoints.first else { continue }
                        path.move(to: firstPoint)
                        for point in transformedPoints.dropFirst() {
                            path.addLine(to: point)
                        }

                        context.stroke(
                            path,
                            with: .color(Color(uiColor: stroke.color.toUIColor())),
                            lineWidth: stroke.thickness / 10
                        )
                    }
                }
                .background(background)
                .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(background)
                    .frame(width: 60, height: 40)
            }
        }
        .frame(width: 60, height: 40)
    }

    private func calculateTransform(for frame: Frame, in size: CGSize) -> (offset: CGPoint, scale: CGFloat)? {
        let allPoints = frame.strokes.flatMap { $0.points }
        guard !allPoints.isEmpty else { return nil }

        let minX = allPoints.map(\ .x).min() ?? 0
        let maxX = allPoints.map(\ .x).max() ?? 0
        let minY = allPoints.map(\ .y).min() ?? 0
        let maxY = allPoints.map(\ .y).max() ?? 0

        let boundingWidth = maxX - minX
        let boundingHeight = maxY - minY

        let scaleX = size.width / boundingWidth
        let scaleY = size.height / boundingHeight
        let scale = min(scaleX, scaleY) * 0.8

        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        let offsetX = size.width / 2 - (centerX * scale)
        let offsetY = size.height / 2 - (centerY * scale)

        return (offset: CGPoint(x: offsetX, y: offsetY), scale: scale)
    }
}

struct FramePreviewComponent_Previews: PreviewProvider {
    static var previews: some View {
        let dummyStroke = Stroke(
            points: [
                Point(x: 0.1, y: 0.2, z: 0),
                Point(x: 0.4, y: 0.6, z: 0),
                Point(x: 0.9, y: 0.8, z: 0)
            ],
            color: CodableColor(from: .red),
            thickness: 20
        )
        let dummyFrame = Frame(strokes: [dummyStroke])
        return FramePreviewComponent(frame: dummyFrame)
            .previewDisplayName("Frame Preview Component")
            .previewLayout(.sizeThatFits)
            .background(Color.background)
    }
}
