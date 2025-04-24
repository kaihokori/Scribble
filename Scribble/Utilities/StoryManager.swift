//
//  StoryManager.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import Foundation
import SwiftUI
import SceneKit

class StoryManager: ObservableObject {
    @Published var story: Story
    @Published var isRepositioning = true
    @Published var selectedObjectForRepositioning: Object? = nil

    init() {
        self.story = Story(title: "story", objects: [])

        if let loadedStory = loadStoryFromAssets() {
            self.story = loadedStory
        }
    }

    private func loadStoryFromAssets() -> Story? {
        guard let asset = NSDataAsset(name: "story") else {
            print("No story.json found in Assets.xcassets.")
            return nil
        }

        do {
            let jsonData = asset.data
            let decoder = JSONDecoder()
            return try decoder.decode(Story.self, from: jsonData)
        } catch {
            print("Failed to decode story.json from assets:", error)
            return nil
        }
    }
    
    func startRepositioningAll() {
        isRepositioning = true
        selectedObjectForRepositioning = nil
    }

    func startRepositioningObject(_ object: Object) {
        isRepositioning = true
        selectedObjectForRepositioning = object
    }

    func finishRepositioning() {
        isRepositioning = false
        selectedObjectForRepositioning = nil
    }
    
    func updateRepositioningState(_ state: Bool) {
        isRepositioning = state
    }
    
    func setActiveFrame(for objectID: UUID, to index: Int) {
        guard let objectIndex = story.objects.firstIndex(where: { $0.id == objectID }) else { return }

        if index >= 0 && index < story.objects[objectIndex].frames.count {
            story.objects[objectIndex].activeFrameIndex = index
        }
    }
    
    func setPlaybackDirection(for objectID: UUID, to direction: Int) {
        guard let objectIndex = story.objects.firstIndex(where: { $0.id == objectID }) else { return }
        story.objects[objectIndex].direction = direction
    }

    func exportToUSDZ() -> URL? {
        let documentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(story.title)")
            .appendingPathExtension("usdz")

        let scene = SCNScene()
        
        var minY: Float = .greatestFiniteMagnitude
        var maxY: Float = -.greatestFiniteMagnitude
        var minX: Float = .greatestFiniteMagnitude
        var maxX: Float = -.greatestFiniteMagnitude
        var minZ: Float = .greatestFiniteMagnitude
        var maxZ: Float = -.greatestFiniteMagnitude
        
        for object in story.objects {
            for frame in object.frames {
                for stroke in frame.strokes {
                    for point in stroke.points {
                        minY = min(minY, Float(point.y))
                        maxY = max(maxY, Float(point.y))
                        minX = min(minX, Float(point.x))
                        maxX = max(maxX, Float(point.x))
                        minZ = min(minZ, Float(point.z))
                        maxZ = max(maxZ, Float(point.z))
                    }
                }
            }
        }
        
        let yOffset = minY < 0 ? -minY : -((maxY + minY) / 2)
        let xOffset = -((maxX + minX) / 2)
        let zOffset = -((maxZ + minZ) / 2)
        
        for object in story.objects {
            let objectNode = SCNNode()
            
            objectNode.position = SCNVector3(object.position.x + xOffset, object.position.y + yOffset, object.position.z + zOffset)
            objectNode.orientation = SCNQuaternion(object.orientation.vector.x, object.orientation.vector.y, object.orientation.vector.z, object.orientation.vector.w)
            
            bakeFrames(to: objectNode, for: object, xOffset: xOffset, yOffset: yOffset, zOffset: zOffset)
            scene.rootNode.addChildNode(objectNode)
        }
        
        scene.write(to: documentURL, options: nil, delegate: nil, progressHandler: nil)
        return documentURL
    }
    
    func exportToJSON() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(story)
            let documentURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(story.title)")
                .appendingPathExtension("json")

            try jsonData.write(to: documentURL)
            print("Story exported to:", documentURL)
            return documentURL
        } catch {
            print("Failed to export story:", error)
            return nil
        }
    }
    
    private func bakeFrames(to node: SCNNode, for object: Object, xOffset: Float, yOffset: Float, zOffset: Float) {
        guard let firstFrame = object.frames.first else { return }

        let frameNode = SCNNode()
        for stroke in firstFrame.strokes {
            let strokeNode = createStrokeNode(from: stroke, xOffset: xOffset, yOffset: yOffset, zOffset: zOffset)
            frameNode.addChildNode(strokeNode)
        }

        let frameLabel = SCNNode()
        frameLabel.name = "Frame-0"
        frameNode.addChildNode(frameLabel)
        node.addChildNode(frameNode)
    }

    private func createStrokeNode(from stroke: Stroke, xOffset: Float, yOffset: Float, zOffset: Float) -> SCNNode {
        let strokeNode = SCNNode()

        for i in 1..<stroke.points.count {
            let start = SCNVector3(x: Float(stroke.points[i - 1].x) + xOffset, y: Float(stroke.points[i - 1].y) + yOffset, z: Float(stroke.points[i - 1].z) + zOffset)
            let end = SCNVector3(x: Float(stroke.points[i].x) + xOffset, y: Float(stroke.points[i].y) + yOffset, z: Float(stroke.points[i].z) + zOffset)
            let lineSegment = createLineSegment(from: start, to: end, color: stroke.color.toUIColor())
            strokeNode.addChildNode(lineSegment)
        }

        return strokeNode
    }

    private func createLineSegment(from start: SCNVector3, to end: SCNVector3, color: UIColor) -> SCNNode {
        let direction = SCNVector3(
            end.x - start.x,
            end.y - start.y,
            end.z - start.z
        )

        let height = distanceBetween(start, end)
        let cylinder = SCNCylinder(radius: 0.005, height: CGFloat(height))
        cylinder.firstMaterial?.diffuse.contents = color

        let lineNode = SCNNode(geometry: cylinder)
        lineNode.position = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )

        lineNode.rotation = calculateRotationFromVector(direction)

        return lineNode
    }

    private func distanceBetween(_ start: SCNVector3, _ end: SCNVector3) -> Float {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    private func calculateRotationFromVector(_ vector: SCNVector3) -> SCNVector4 {
        let upVector = SCNVector3(0, 1, 0)
        let crossProduct = SCNVector3(
            upVector.y * vector.z - upVector.z * vector.y,
            upVector.z * vector.x - upVector.x * vector.z,
            upVector.x * vector.y - upVector.y * vector.x
        )
        
        let dotProduct = upVector.x * vector.x + upVector.y * vector.y + upVector.z * vector.z
        let angle = acos(dotProduct / (sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)))

        return SCNVector4(crossProduct.x, crossProduct.y, crossProduct.z, angle)
    }
    
    func renameObject(_ object: Object, newName: String) {
        if let index = story.objects.firstIndex(where: { $0.id == object.id }) {
            story.objects[index].name = newName
        }
    }
    
    func deleteObject(_ object: Object) {
        if let index = story.objects.firstIndex(where: { $0.id == object.id }) {
            story.objects.remove(at: index)
        }
    }
    
    func duplicateObject(_ object: Object) -> Object {
        var newObject = object
        newObject.id = UUID()
        newObject.position.x += 0.01
        newObject.position.y += 0.01
        story.objects.append(newObject)
        return newObject
    }

}
