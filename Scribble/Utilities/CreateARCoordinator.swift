//
//  CreateARCoordinator.swift
//  Scribble
//
//  Created by Kyle Graham on 14/2/2025.
//

import SwiftUI
import ARKit

@MainActor
class CreateARCoordinator: NSObject, ARSCNViewDelegate, ObservableObject {
    @Published var isSnapping: Bool = false {
        didSet {
            UserDefaults.standard.set(isSnapping, forKey: "isSnapping3D")
        }
    }

    @Published var snapDistance: Float = 0.03 {
        didSet {
            UserDefaults.standard.set(Double(snapDistance), forKey: "snapDistance3D")
        }
    }

    @Published var drawingDistance: Float = 0.1 {
        didSet {
            UserDefaults.standard.set(Double(drawingDistance), forKey: "drawingDistance3D")
        }
    }
    @Published var hasValidStroke: Bool = false
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false

    var strokes: [SCNNode] = []
    var redoStack: [SCNNode] = []
    var currentStrokeNode: SCNNode?
    var currentLinePoints: [SCNVector3] = []
    var isDrawing = false
    var drawingTimer: Timer?
    var sceneView: ARSCNView?
    var strokeThickness: CGFloat = 20 / 2 / 10000
    var selectedColor: UIColor = .red
    private var currentObject: Binding<Object>?
    private var currentFrameIndex: Binding<Int>?

    override init() {
        super.init()
        
        self.isSnapping = UserDefaults.standard.bool(forKey: "isSnapping3D")
        self.snapDistance = Float(UserDefaults.standard.double(forKey: "snapDistance3D"))
        self.drawingDistance = Float(UserDefaults.standard.double(forKey: "drawingDistance3D"))
    }
    
    func setupBindings(currentObject: Binding<Object>, currentFrameIndex: Binding<Int>) {
        self.currentObject = currentObject
        self.currentFrameIndex = currentFrameIndex
    }

    func startDrawing(in sceneView: ARSCNView) {
        guard !isDrawing else { return }
        isDrawing = true
        self.sceneView = sceneView
        currentLinePoints.removeAll()
        currentStrokeNode = SCNNode()
        sceneView.scene.rootNode.addChildNode(currentStrokeNode!)

        if let currentPosition = getCurrentPosition(in: sceneView) {
            currentLinePoints.append(currentPosition)
            updateLineNode(currentStrokeNode, with: currentLinePoints)
        }

        drawingTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.continueDrawing()
            }
        }
    }

    func continueDrawing() {
        guard let sceneView = sceneView else { return }
        
        if var currentPosition = getCurrentPosition(in: sceneView) {
            if isSnapping, let snappedPosition = findNearestSnapPoint(to: currentPosition) {
                currentPosition = snappedPosition
            }
            currentLinePoints.append(currentPosition)
            updateLineNode(currentStrokeNode, with: currentLinePoints)
        }
    }

    func stopDrawing() {
        guard isDrawing else { return }
        isDrawing = false
        drawingTimer?.invalidate()
        drawingTimer = nil

        if let strokeNode = currentStrokeNode, currentLinePoints.count > 1 {
            strokes.append(strokeNode)
            redoStack.removeAll()
            
            DispatchQueue.main.async {
                self.saveCurrentFrame()
            }
        }
        currentStrokeNode = nil
    }
    
    func updateLineNode(_ node: SCNNode?, with points: [SCNVector3]) {
        guard points.count > 1 else { return }

        node?.childNodes.forEach { $0.removeFromParentNode() }

        for i in 1..<points.count {
            let start = points[i - 1]
            let end = points[i]
            let distance = distanceBetween(start, end)

            if distance > drawingDistance * 1.5 {
                let interpolatedPoints = interpolatePoints(from: start, to: end, step: drawingDistance * 0.5)
                for j in 1..<interpolatedPoints.count {
                    let segment = createLineSegment(from: interpolatedPoints[j - 1], to: interpolatedPoints[j], color: selectedColor, thickness: strokeThickness)
                    node?.addChildNode(segment)
                }
            } else {
                let segment = createLineSegment(from: start, to: end, color: selectedColor, thickness: strokeThickness)
                node?.addChildNode(segment)
            }
        }
    }
    
    func createLineSegment(from start: SCNVector3, to end: SCNVector3, color: UIColor, thickness: CGFloat) -> SCNNode {
        let height = CGFloat(distanceBetween(start, end))
        let cylinder = SCNCylinder(radius: thickness / 8, height: height)
        cylinder.firstMaterial?.diffuse.contents = color

        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        node.look(at: end, up: sceneView?.scene.rootNode.worldUp ?? SCNVector3(0, 1, 0), localFront: node.worldUp)
        return node
    }
    
    private func distanceBetween(_ start: SCNVector3, _ end: SCNVector3) -> Float {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    func interpolatePoints(from start: SCNVector3, to end: SCNVector3, step: Float) -> [SCNVector3] {
        var points: [SCNVector3] = []
        let distance = distanceBetween(start, end)
        
        if distance.isNaN || distance.isInfinite || step.isNaN || step.isInfinite || step <= 0 {
            print("Invalid interpolation parameters: distance = \(distance), step = \(step)")
            return []
        }

        guard step > 0 else {
            print("Step must be greater than zero, received \(step)")
            return []
        }
        let numSteps = max(1, Int(distance / step))
        if numSteps > 0 {
            for i in 1...numSteps {
                let t = Float(i) / Float(numSteps)
                let interpolatedPoint = SCNVector3(
                    start.x + t * (end.x - start.x),
                    start.y + t * (end.y - start.y),
                    start.z + t * (end.z - start.z)
                )
                points.append(interpolatedPoint)
            }
        }

        return points
    }
    
    private func findNearestSnapPoint(to point: SCNVector3) -> SCNVector3? {
        var nearestPoint: SCNVector3?
        var minDistance: Float = snapDistance

        for stroke in strokes {
            for segment in stroke.childNodes {
                let segmentPosition = segment.position
                let distance = distanceBetween(point, segmentPosition)

                if distance < minDistance {
                    minDistance = distance
                    nearestPoint = segmentPosition
                }
            }
        }
        
        return nearestPoint
    }
    
    func undoLastStroke() {
        guard let lastStroke = strokes.popLast() else { return }
        redoStack.append(lastStroke)
        lastStroke.removeFromParentNode()

        DispatchQueue.main.async {
            self.saveCurrentFrame()
        }
    }

    func redoLastStroke() {
        guard let lastRedoStroke = redoStack.popLast() else { return }
        strokes.append(lastRedoStroke)
        sceneView?.scene.rootNode.addChildNode(lastRedoStroke)

        DispatchQueue.main.async {
            self.saveCurrentFrame()
        }
    }

    func clearAllStrokes() {
        strokes.forEach { $0.removeFromParentNode() }
        strokes.removeAll()
        redoStack.removeAll()

        DispatchQueue.main.async {
            self.saveCurrentFrame()
        }
    }
    
    private func saveCurrentFrame() {
        guard let currentObject = currentObject, let currentFrameIndex = currentFrameIndex else { return }

        DispatchQueue.main.async {
            var extractedStrokes: [Stroke] = []

            for strokeNode in self.strokes {
                var points: [Point] = []
                var strokeColor: UIColor = .black
                var strokeThickness: CGFloat = 1.0

                for segment in strokeNode.childNodes {
                    if let position = segment.position as SCNVector3? {
                        points.append(Point(x: CGFloat(position.x), y: CGFloat(position.y), z: CGFloat(position.z)))
                    }
                    if let geometry = segment.geometry as? SCNCylinder {
                        if let material = geometry.firstMaterial, let diffuse = material.diffuse.contents as? UIColor {
                            strokeColor = diffuse
                        }
                        strokeThickness = geometry.radius * 8 * 1000
                    }
                }

                let stroke = Stroke(points: points, color: CodableColor(from: strokeColor), thickness: strokeThickness)
                extractedStrokes.append(stroke)
            }

            currentObject.wrappedValue.frames[currentFrameIndex.wrappedValue].strokes = extractedStrokes
            self.hasValidStroke = !extractedStrokes.isEmpty
            self.canUndo = self.hasValidStroke
            self.canRedo = !self.redoStack.isEmpty
        }
    }
    
    func loadFrame(_ frame: Frame) {
        clearAllStrokes()
        
        for stroke in frame.strokes {
            let strokeNode = SCNNode()
            
            var previousPoint: SCNVector3?
            for point in stroke.points {
                let currentPoint = SCNVector3(Float(point.x), Float(point.y), Float(point.z))
                
                if let previous = previousPoint {
                    let segment = createLineSegment(from: previous, to: currentPoint, color: stroke.color.toUIColor(), thickness: stroke.thickness / 1000)
                    strokeNode.addChildNode(segment)
                }
                previousPoint = currentPoint
            }
            
            sceneView?.scene.rootNode.addChildNode(strokeNode)
            strokes.append(strokeNode)
        }

        DispatchQueue.main.async {
            self.updateHasValidStroke()
        }
    }

    func updateColor(_ color: Color) {
        selectedColor = UIColor(color)
    }
    
    func updateThickness(_ thickness: CGFloat) {
        strokeThickness = thickness / 1000
    }

    func getCurrentPosition(in sceneView: ARSCNView) -> SCNVector3? {
        guard let frame = sceneView.session.currentFrame else { return nil }
        let cameraTransform = frame.camera.transform
        let forward = SCNVector3(-cameraTransform.columns.2.x, -cameraTransform.columns.2.y, -cameraTransform.columns.2.z)
        return SCNVector3(
            x: cameraTransform.columns.3.x + forward.x * drawingDistance,
            y: cameraTransform.columns.3.y + forward.y * drawingDistance,
            z: cameraTransform.columns.3.z + forward.z * drawingDistance
        )
    }
    
    private func updateHasValidStroke() {
        hasValidStroke = strokes.contains { $0.childNodes.count > 1 }
        canUndo = hasValidStroke
        canRedo = !redoStack.isEmpty
    }
}
