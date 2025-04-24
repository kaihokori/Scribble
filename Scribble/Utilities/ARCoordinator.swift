//
//  ARCoordinator.swift
//  Scribble
//
//  Created by Kyle Graham on 14/12/2024.
//

import ARKit
import SceneKit
import CoreMotion

@MainActor
class ARCoordinator: NSObject, ARSCNViewDelegate {
    var storyManager: StoryManager
    var isRepositioning: Bool = false
    private var rootNode: SCNNode = SCNNode()
    weak static var shared: ARCoordinator?
    private var arView: ARSCNView?

    init(storyManager: StoryManager) {
        self.storyManager = storyManager
        super.init()
        ARCoordinator.shared = self
    }

    // MARK: - Setup AR Session
    func setupARSession(for view: ARSCNView) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        view.session.run(configuration)
        view.scene.rootNode.addChildNode(rootNode)
        self.arView = view
    }

    func pauseSession() {
        arView?.session.pause()
    }

    func restartSession() {
        guard let view = arView else { return }
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - Update Scene
    func updateScene() {
        rootNode.enumerateChildNodes { node, _ in
            node.removeFromParentNode()
        }

        if storyManager.isRepositioning, storyManager.selectedObjectForRepositioning == nil {
            return
        }

        for object in storyManager.story.objects {
            if let selectedObject = storyManager.selectedObjectForRepositioning, selectedObject.id == object.id {
                continue
            }

            let objectNode = createObjectNode(from: object)

            if storyManager.isRepositioning, storyManager.selectedObjectForRepositioning != nil {
                applyGreyMaterial(to: objectNode)
            }

            rootNode.addChildNode(objectNode)
        }
    }

    
    private func applyGreyMaterial(to node: SCNNode) {
        let greyMaterial = SCNMaterial()
        greyMaterial.diffuse.contents = UIColor.gray

        if let geometry = node.geometry {
            geometry.firstMaterial = greyMaterial
        }

        for child in node.childNodes {
            applyGreyMaterial(to: child)
        }
    }

    private func createObjectNode(from object: Object) -> SCNNode {
        let objectNode = SCNNode()
        objectNode.name = object.id.uuidString
        objectNode.position = SCNVector3(object.position)
        objectNode.orientation = SCNQuaternion(object.orientation.vector.x, object.orientation.vector.y, object.orientation.vector.z, object.orientation.vector.w)

        if object.frames.indices.contains(object.activeFrameIndex) {
            let activeFrame = object.frames[object.activeFrameIndex]
            for stroke in activeFrame.strokes {
                let strokeNode = createStrokeNode(from: stroke)
                objectNode.addChildNode(strokeNode)
            }
        }

        return objectNode
    }

    private func createStrokeNode(from stroke: Stroke) -> SCNNode {
        let strokeNode = SCNNode()
        guard stroke.points.count > 1 else { return strokeNode }
        
        let vertices = stroke.points.map { point in
            SCNVector3(x: Float(point.x), y: Float(point.y), z: Float(point.z))
        }
        
        let tubeGeometry = createTubeGeometry(from: vertices, radius: Float(stroke.thickness) / 2000.0 / 3, radialSegmentCount: 8)
        
        let material = SCNMaterial()
        material.diffuse.contents = stroke.color.toUIColor()
        tubeGeometry.materials = [material]
        
        strokeNode.geometry = tubeGeometry
        return strokeNode
    }

    func createTubeGeometry(from points: [SCNVector3], radius: Float, radialSegmentCount: Int) -> SCNGeometry {
        guard points.count >= 2 else { return SCNGeometry() }
        
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [UInt32] = []
        
        for i in 0..<points.count {
            let point = points[i]
            let forward: SCNVector3
            if i == 0 {
                forward = (points[i+1] - point).normalized()
            } else if i == points.count - 1 {
                forward = (point - points[i-1]).normalized()
            } else {
                forward = (points[i+1] - points[i-1]).normalized()
            }
            
            let up = SCNVector3(0, 1, 0)
            var tangent = forward.cross(up).normalized()
            if tangent.length() == 0 {
                tangent = SCNVector3(1, 0, 0)
            }
            let bitangent = forward.cross(tangent).normalized()
            
            for j in 0..<radialSegmentCount {
                let theta = (Float(j) / Float(radialSegmentCount)) * (2 * Float.pi)
                let offset = tangent * cos(theta) * radius + bitangent * sin(theta) * radius
                vertices.append(point + offset)
                normals.append(offset.normalized())
            }
        }
        
        let circleVertexCount = radialSegmentCount
        for i in 0..<(points.count - 1) {
            for j in 0..<radialSegmentCount {
                let current = i * circleVertexCount + j
                let next = current + circleVertexCount
                let nextInCircle = i * circleVertexCount + ((j + 1) % circleVertexCount)
                let nextInCircleNext = nextInCircle + circleVertexCount
                
                indices.append(UInt32(current))
                indices.append(UInt32(next))
                indices.append(UInt32(nextInCircle))
                
                indices.append(UInt32(nextInCircle))
                indices.append(UInt32(next))
                indices.append(UInt32(nextInCircleNext))
            }
        }
        
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals: normals)
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<UInt32>.size)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .triangles,
                                         primitiveCount: indices.count / 3,
                                         bytesPerIndex: MemoryLayout<UInt32>.size)
        
        let geometry = SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
        return geometry
    }
    
    private func createLineSegment(from start: SCNVector3, to end: SCNVector3, color: CodableColor, thickness: CGFloat) -> SCNNode {
        let radius = thickness / 2.0 / 3000
        let height = CGFloat(distanceBetween(start, end))

        let cylinder = SCNCylinder(radius: radius, height: height)
        cylinder.firstMaterial?.diffuse.contents = color.toUIColor()

        let lineNode = SCNNode(geometry: cylinder)
        lineNode.position = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        lineNode.look(at: end, up: rootNode.worldUp, localFront: lineNode.worldUp)

        return lineNode
    }

    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        guard let arView = gestureRecognize.view as? ARSCNView else { return }

        let location = gestureRecognize.location(in: arView)
        if isRepositioning {
            if let selectedObject = storyManager.selectedObjectForRepositioning {
                repositionSingleObject(selectedObject, at: location, in: arView)
            } else {
                repositionAllObjects(at: location, in: arView)
            }
            isRepositioning = false
            storyManager.finishRepositioning()
            updateScene()
        }
    }

    private func repositionAllObjects(at location: CGPoint, in view: ARSCNView) {
        guard let frame = view.session.currentFrame else { return }
        
        let newAnchorPosition = calculateNewPosition(from: frame)
        let newOrientation = calculateNewOrientation(from: frame, to: newAnchorPosition)
        
        let originalCenter = computeCenter(of: storyManager.story.objects)
        
        for (index, object) in storyManager.story.objects.enumerated() {
            let offset = SIMD3<Float>(object.position.x, object.position.y, object.position.z) - originalCenter
            let updatedPosition = newAnchorPosition + offset
            
            storyManager.story.objects[index].position = updatedPosition
            storyManager.story.objects[index].orientation = newOrientation
        }
    }

    private func computeCenter(of objects: [Object]) -> SIMD3<Float> {
        var center = SIMD3<Float>(0, 0, 0)
        for object in objects {
            center += SIMD3<Float>(object.position.x, object.position.y, object.position.z)
        }
        return center / Float(objects.count)
    }

    private func repositionSingleObject(_ object: Object, at location: CGPoint, in view: ARSCNView) {
        guard let frame = view.session.currentFrame else { return }
        let newPosition = calculateNewPosition(from: frame)
        let newOrientation = calculateNewOrientation(from: frame, to: newPosition)

        if let index = storyManager.story.objects.firstIndex(where: { $0.id == object.id }) {
            storyManager.story.objects[index].position = newPosition
            storyManager.story.objects[index].orientation = newOrientation
        }
    }

    private func calculateNewPosition(from frame: ARFrame) -> SIMD3<Float> {
        let cameraTransform = frame.camera.transform
        let forwardDistance: Float = 0.4
        let cameraPosition = SIMD3<Float>(
            x: cameraTransform.columns.3.x,
            y: cameraTransform.columns.3.y - 0.05,
            z: cameraTransform.columns.3.z
        )
        let forwardVector = normalize(SIMD3<Float>(
            x: -cameraTransform.columns.2.x,
            y: 0,
            z: -cameraTransform.columns.2.z
        ))
        return cameraPosition + forwardVector * forwardDistance
    }

    private func calculateNewOrientation(from frame: ARFrame, to position: SIMD3<Float>) -> simd_quatf {
        let cameraTransform = frame.camera.transform
        let cameraPosition = SIMD3<Float>(
            x: cameraTransform.columns.3.x,
            y: cameraTransform.columns.3.y,
            z: cameraTransform.columns.3.z
        )
        let objectToCamera = normalize(SIMD3<Float>(
            x: cameraPosition.x - position.x,
            y: 0,
            z: cameraPosition.z - position.z
        ))
        let upVector = SIMD3<Float>(0, 1, 0)
        let rightVector = cross(upVector, objectToCamera)
        let adjustedUpVector = cross(objectToCamera, rightVector)

        let orientationMatrix = float3x3(rightVector, adjustedUpVector, objectToCamera)
        return simd_quatf(orientationMatrix)
    }

    private func distanceBetween(_ start: SCNVector3, _ end: SCNVector3) -> Float {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    
}

extension SCNVector3 {
    static func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    static func *(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        return SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
    func length() -> Float {
        return sqrt(x * x + y * y + z * z)
    }
    func normalized() -> SCNVector3 {
        let len = self.length()
        return len == 0 ? self : self * (1 / len)
    }
    func cross(_ vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            y * vector.z - z * vector.y,
            z * vector.x - x * vector.z,
            x * vector.y - y * vector.x
        )
    }
}
