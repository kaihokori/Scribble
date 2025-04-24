//
//  DrawingViewModel.swift
//  Scribble
//
//  Created by Kyle Graham on 4/2/2025.
//

import SwiftUI

class DrawingViewModel: ObservableObject {
    @Published var strokes: [Drawing2DStroke] = []
    @Published var tempStrokes: [Drawing2DStroke] = []
    
    private var undoStack: [Action] = []
    private var redoStack: [Action] = []

    @Published var currentStroke: Drawing2DStroke = Drawing2DStroke(points: [], color: .black, thickness: 1)
    @Published var currentStrokePath: Path?

    enum Action {
        case draw(Drawing2DStroke)
        case erase([Drawing2DStroke])
    }

    var canUndo: Bool {
        !strokes.isEmpty || !undoStack.isEmpty
    }

    var canRedo: Bool {
        !redoStack.isEmpty
    }

    var hasStrokes: Bool {
        !strokes.isEmpty
    }

    func addPoint(_ point: CGPoint, color: Color, thickness: CGFloat, isErasing: Bool) {
        if isErasing {
            let erasedStrokes = strokes.filter { stroke in
                stroke.points.contains(where: { $0.distance(to: point) < thickness })
            }
            strokes.removeAll { stroke in
                erasedStrokes.contains(where: { $0.id == stroke.id })
            }
            if !erasedStrokes.isEmpty {
                undoStack.append(.erase(erasedStrokes))
                redoStack.removeAll()
            }
        } else {
            if currentStroke.points.isEmpty {
                currentStroke = Drawing2DStroke(points: [point], color: color, thickness: thickness)
                tempStrokes.append(currentStroke)
            } else {
                currentStroke.points.append(point)
                if let lastIndex = tempStrokes.indices.last {
                    tempStrokes[lastIndex] = currentStroke
                }
            }
            updateCurrentStrokePath()
            
            objectWillChange.send()
        }
    }

    func endStroke() {
        guard !currentStroke.points.isEmpty else { return }
        
        strokes.append(currentStroke)
        undoStack.append(.draw(currentStroke))
        redoStack.removeAll()
        
        tempStrokes.removeAll()
        
        currentStroke = Drawing2DStroke(points: [], color: .black, thickness: 1)
    }

    func undo() {
        guard canUndo else { return }
        let lastAction = undoStack.removeLast()
        switch lastAction {
        case .draw(let stroke):
            strokes.removeAll { $0.id == stroke.id }
            redoStack.append(lastAction)
        case .erase(let erasedStrokes):
            strokes.append(contentsOf: erasedStrokes)
            redoStack.append(lastAction)
        }
    }

    func redo() {
        guard canRedo else { return }
        let lastRedoAction = redoStack.removeLast()
        switch lastRedoAction {
        case .draw(let stroke):
            strokes.append(stroke)
            undoStack.append(lastRedoAction)
        case .erase(let erasedStrokes):
            strokes.removeAll { stroke in
                erasedStrokes.contains(where: { $0.id == stroke.id })
            }
            undoStack.append(lastRedoAction)
        }
    }

    func clearAll() {
        strokes.removeAll()
        tempStrokes.removeAll()
        undoStack.removeAll()
        redoStack.removeAll()
        currentStroke = Drawing2DStroke(points: [], color: .black, thickness: 1)
        currentStrokePath = nil
    }

    func renderStroke(_ stroke: Drawing2DStroke, resolution: Int) -> some View {
        let simplifiedPoints = simplifyPath(stroke.points, nodeCount: resolution)
        return Path { path in
            guard let first = simplifiedPoints.first else { return }
            path.move(to: first)
            for point in simplifiedPoints.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(stroke.color, lineWidth: stroke.thickness)
    }

    private func simplifyPath(_ points: [CGPoint], nodeCount: Int) -> [CGPoint] {
        guard points.count > 1 else { return points }
        guard nodeCount > 1 else { return [points.first!, points.last!] }

        let step = Double(points.count - 1) / Double(max(1, nodeCount - 1))
        return (0..<nodeCount).map { points[Int(round(Double($0) * step))] }
    }

    private func updateCurrentStrokePath() {
        var path = Path()
        if let firstPoint = currentStroke.points.first {
            path.move(to: firstPoint)
            for point in currentStroke.points.dropFirst() {
                path.addLine(to: point)
            }
        }
        currentStrokePath = path
    }
}
