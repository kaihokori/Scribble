//
//  Create3DView.swift
//  Scribble
//
//  Created by Kyle Graham on 31/1/2025.
//

import SwiftUI
import simd

struct Create3DView: View {
    @Binding var navigationPath: NavigationPath
    @State private var isDrawing: Bool = false
    @State private var isPlaying = false
    @State private var shapeName: String = ""
    @State private var selectedColor: Color = .red
    @State private var selectedThickness: CGFloat = 20
    @State private var showSettingsMenu: Bool = false
    @State private var showColorPicker: Bool = false
    @State private var showFrameMenu: Bool = false
    @State private var showClearAlert: Bool = false
    @State private var showContinueAlert: Bool = false
    @State private var showPlaybackSettingsMenu: Bool = false
    @State private var canUndo: Bool = false
    @State private var canRedo: Bool = false
    @State private var hasValidStroke: Bool = false
    @State var currentObject: Object
    @State var currentFrameIndex: Int = 0
    @State private var playbackTimer: Timer?
    @State private var playbackDirection: Int = 1
    @State private var showHelp: Bool = false
    @StateObject private var arCoordinator = CreateARCoordinator()

    var storyManager: StoryManager

    init(navigationPath: Binding<NavigationPath>, storyManager: StoryManager) {
        _navigationPath = navigationPath
        self.storyManager = storyManager
        let initialObject = Object(
            name: "New Object",
            frames: [Frame(strokes: [])],
            playbackSetting: .loop,
            position: SIMD3<Float>(0, 0, -0.3),
            orientation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        )
        _currentObject = State(initialValue: initialObject)
        _currentFrameIndex = State(initialValue: 0)
    }
    
    var helpItems = [
        HelpItem(symbol: "hand.draw", heading: "Draw", body: "Hold anywhere on the screen and move your device to create each stroke, just like a brush"),
        HelpItem(symbol: "rectangle.portrait.arrowtriangle.2.outward", heading: "Animate", body: "Build multiple frames, adjust playback settings, and see your creation come to life"),
        HelpItem(symbol: "dot.viewfinder", heading: "Snap", body: "Enable and adjust snapping in settings to easily connect nearby strokes"),
        HelpItem(symbol: "hand.tap", heading: "Organise", body: "Tap a frame to select it, then tap again to move, duplicate, or delete it")
    ];

    var body: some View {
        ZStack {
            CreateARViewContainer(selectedColor: $selectedColor, selectedThickness: $selectedThickness, isDrawing: $isDrawing, arCoordinator: arCoordinator)
                .edgesIgnoringSafeArea(.all)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isDrawing {
                                closeOverlays()
                                isDrawing = true
                            }
                        }
                        .onEnded { _ in
                            isDrawing = false
                        }
                )
                .onReceive(arCoordinator.$hasValidStroke) { hasValidStroke = $0 }
                .onReceive(arCoordinator.$canUndo) { canUndo = $0 }
                .onReceive(arCoordinator.$canRedo) { canRedo = $0 }

            VStack {
                HStack {
                    ButtonComponent(text: "Return", foregroundColor: Color.accentColor) {
                        navigationPath.removeLast()
                    }
                    
                    ButtonComponent(symbol: "gear", isWide: true) {
                        if !showSettingsMenu {
                            closeOverlays()
                            showSettingsMenu = true
                        } else {
                            closeOverlays()
                        }
                    }
                    .frame(width: 60, height: 40)
                    
                    ButtonComponent(symbol: "questionmark", isWide: true) {
                        closeOverlays()
                        showHelp = true
                    }
                    .frame(width: 60, height: 40)

                    Spacer()
                    
                    ButtonComponent(text: "Continue", foregroundColor: Color.accentColor, isEnabled: hasValidStrokeInCurrentFrame) {
                        closeOverlays()
                        showContinueAlert = true
                    }
                    .alert("Name Object", isPresented: $showContinueAlert) {
                        TextField("Umbrella", text: $shapeName)
                        Button("Cancel", role: .cancel) {}
                        Button("Continue") {
                            let newObject = save3DObject(named: shapeName.isEmpty ? "Unnamed Shape" : shapeName)
                            storyManager.startRepositioningObject(newObject)
                            navigationPath.removeLast(2)
                        }
                        .disabled(shapeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Spacer()

                HStack {
                    VStack {
                        ZStack {
                            Circle()
                                .strokeBorder(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            .red, .orange, .yellow, .green, .blue, .purple, .red
                                        ]),
                                        center: .center
                                    ),
                                    lineWidth: 6
                                )
                                .frame(width: 55, height: 55)

                            Circle()
                                .fill(selectedColor)
                                .frame(width: 35, height: 35)
                                .onTapGesture {
                                    if !showColorPicker {
                                        closeOverlays()
                                        showColorPicker = true
                                    } else {
                                        closeOverlays()
                                    }
                                }
                        }
                        
                        ButtonComponent(symbol: "arrow.uturn.backward", isCircular: true, isEnabled: arCoordinator.hasValidStroke, action: {
                            closeOverlays()
                            arCoordinator.undoLastStroke()
                        })
                        .padding(.top, 40)
                        .padding(.bottom, 10)

                        ButtonComponent(symbol: "arrow.uturn.forward", isCircular: true, isEnabled: arCoordinator.canRedo, action: {
                            closeOverlays()
                            arCoordinator.redoLastStroke()
                        })

                        ButtonComponent(symbol: "trash", isCircular: true, isEnabled: arCoordinator.hasValidStroke, action: {
                            closeOverlays()
                            showClearAlert = true
                        })
                        .padding(.top, 40)
                        .alert("Clear all strokes?", isPresented: $showClearAlert) {
                            Button("Clear All", role: .destructive) {
                                arCoordinator.clearAllStrokes()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This action will permanently remove all strokes and cannot be undone.")
                        }
                    }
                    .frame(width: 60)
                    Spacer()
                }

                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10.0)
                        .foregroundStyle(Color.background_alt)
                    
                    HStack {
                        ButtonComponent(symbol: "slider.horizontal.3", isCircular: true, backgroundColor: Color.background) {
                            if !showPlaybackSettingsMenu {
                                closeOverlays()
                                showPlaybackSettingsMenu = true
                            } else {
                                closeOverlays()
                            }
                        }
                        .frame(width: 60, height: 40)
                        .padding(.leading, 15)
                        .padding(.trailing, 7)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10.0)
                                .foregroundStyle(Color.background)
                                .frame(height: 65)
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(0..<currentObject.frames.count, id: \.self) { index in
                                        FramePreviewComponent(frame: currentObject.frames[index], background: .white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10.0)
                                                    .stroke(index == currentFrameIndex ? Color.accentColor : Color.clear, lineWidth: 3)
                                            )
                                            .onTapGesture {
                                                if !showFrameMenu {
                                                    closeOverlays()
                                                }
                                                if currentFrameIndex == index {
                                                    closeOverlays()
                                                    showFrameMenu = true
                                                } else {
                                                    closeOverlays()
                                                    currentFrameIndex = index
                                                    loadFrame(index: index)
                                                }
                                            }
                                    }
                                    if hasValidStroke && currentFrameIndex == currentObject.frames.count - 1 {
                                        RoundedRectangle(cornerRadius: 10.0)
                                            .fill(Color.white)
                                            .frame(width: 60, height: 40)
                                            .overlay {
                                                Image(systemName: "plus")
                                                    .font(.title2)
                                            }
                                            .onTapGesture {
                                                currentObject.frames.append(Frame(strokes: []))
                                                currentFrameIndex = currentObject.frames.count - 1
                                                arCoordinator.clearAllStrokes()
                                                showFrameMenu = false
                                            }
                                    }
                                }
                                .padding(3)
                            }
                            .scrollIndicators(.hidden)
                            .padding(.horizontal, 12)
                        }
                        ButtonComponent(symbol: isPlaying ? "pause" : "play", isCircular: true, backgroundColor: Color.background) {
                            isPlaying.toggle()
                            if isPlaying {
                                startPlayback()
                            } else {
                                stopPlayback()
                            }
                        }
                        .frame(width: 60, height: 40)
                        .padding(.leading, 7)
                        .padding(.trailing, 15)
                    }
                }
                .frame(height: 80)
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 20 : 100)
            }
            .padding()
            
            if showSettingsMenu {
                VStack {
                    HStack {
                        CreateSettings3DView(isSnapping: $arCoordinator.isSnapping, snapDistance: $arCoordinator.snapDistance, drawingDistance: $arCoordinator.drawingDistance)
                            .offset(x: UIDevice.current.userInterfaceIdiom == .phone ? 18 : 119, y: 85)
                        Spacer()
                    }
                    Spacer()
                }
            }

            if showColorPicker {
                HStack {
                    ColorPickerComponent(selectedColor: $selectedColor, selectedThickness: $selectedThickness)
                        .padding(.leading, UIDevice.current.userInterfaceIdiom == .phone ? 20 : 95)
                        .offset(y: -160)
                    Spacer()
                }
            }
            
            if showPlaybackSettingsMenu {
                VStack {
                    Spacer()
                    HStack {
                        CreatePlaybackSettingsView(playbackSetting: $currentObject.playbackSetting)
                            .offset(x: 117, y: -107)
                        Spacer()
                    }
                }
            }
            
            if showFrameMenu {
                VStack {
                    Spacer()
                    ZStack {
                        Color.background_alt

                        HStack(spacing: 10) {
                            Button(action: moveFrameLeft) {
                                VStack(spacing: 5) {
                                    Image(systemName: "arrow.left")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(height: 35)
                                    Text("Move Left")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 120)
                            }
                            .disabled(currentFrameIndex == 0)
                            .opacity(currentFrameIndex == 0 ? 0.4 : 1.0)
                            
                            Button(action: moveFrameRight) {
                                VStack(spacing: 5) {
                                    Image(systemName: "arrow.right")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(height: 35)
                                    Text("Move Right")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 120)
                            }
                            .disabled(currentFrameIndex == currentObject.frames.count - 1)
                            .opacity(currentFrameIndex == currentObject.frames.count - 1 ? 0.4 : 1.0)
                            
                            Button(action: duplicateFrame) {
                                VStack(spacing: 5) {
                                    Image(systemName: "square.stack.3d.forward.dottedline")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(height: 35)
                                    Text("Duplicate")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 120)
                            }
                            .disabled(currentObject.frames[currentFrameIndex].strokes.isEmpty)
                            .opacity(currentObject.frames[currentFrameIndex].strokes.isEmpty ? 0.4 : 1.0)
                            
                            Button(action: deleteFrame) {
                                VStack(spacing: 5) {
                                    Image(systemName: "trash")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(height: 35)
                                    Text("Delete")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 120)
                            }
                            .disabled(currentObject.frames.count == 1)
                            .opacity(currentObject.frames.count == 1 ? 0.4 : 1.0)
                        }
                        .padding()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(width: 350, height: 100)
                    .offset(y: -105)
                }
            }
        }
        .background(Color.background)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            arCoordinator.setupBindings(currentObject: $currentObject, currentFrameIndex: $currentFrameIndex)
            if UserDefaults.standard.bool(forKey: "show3DHelp") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showHelp = true
                }
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpComponent(title: "Drawing in 3D (In-Space)", helpItems: helpItems) {
                showHelp = false
                UserDefaults.standard.set(false, forKey: "show3DHelp")
            }
        }
    }
    
    func updateHasValidStroke() {
        hasValidStroke = !currentObject.frames[currentFrameIndex].strokes.isEmpty
    }
    
    private var hasValidStrokeInCurrentFrame: Bool {
        return !currentObject.frames[currentFrameIndex].strokes.isEmpty
    }

    private func loadFrame(index: Int) {
        guard index >= 0, index < currentObject.frames.count else { return }
        
        let frame = currentObject.frames[index]
        arCoordinator.loadFrame(frame)
    }
    
    private func save3DObject(named name: String) -> Object {
        guard !arCoordinator.strokes.isEmpty else { fatalError("No strokes to save.") }

        var extractedFrames: [Frame] = []
        var globalMinX: CGFloat = .greatestFiniteMagnitude
        var globalMaxX: CGFloat = -.greatestFiniteMagnitude
        var globalMinY: CGFloat = .greatestFiniteMagnitude
        var globalMaxY: CGFloat = -.greatestFiniteMagnitude
        var globalMinZ: CGFloat = .greatestFiniteMagnitude
        var globalMaxZ: CGFloat = -.greatestFiniteMagnitude

        for frame in currentObject.frames {
            for stroke in frame.strokes {
                for point in stroke.points {
                    globalMinX = min(globalMinX, point.x)
                    globalMaxX = max(globalMaxX, point.x)
                    globalMinY = min(globalMinY, point.y)
                    globalMaxY = max(globalMaxY, point.y)
                    globalMinZ = min(globalMinZ, point.z)
                    globalMaxZ = max(globalMaxZ, point.z)
                }
            }
        }

        let globalCenterX = (globalMinX + globalMaxX) / 2
        let globalCenterY = (globalMinY + globalMaxY) / 2
        let globalCenterZ = (globalMinZ + globalMaxZ) / 2

        for frame in currentObject.frames {
            var adjustedStrokes: [Stroke] = []

            for stroke in frame.strokes {
                var adjustedPoints: [Point] = []

                for point in stroke.points {
                    let newX = point.x - globalCenterX
                    let newY = point.y - globalCenterY
                    let newZ = point.z - globalCenterZ
                    adjustedPoints.append(Point(x: newX, y: newY, z: newZ))
                }

                let newStroke = Stroke(points: adjustedPoints, color: stroke.color, thickness: stroke.thickness)
                adjustedStrokes.append(newStroke)
            }

            extractedFrames.append(Frame(strokes: adjustedStrokes))
        }

        let centeredObject = Object(
            name: name,
            frames: extractedFrames,
            playbackSetting: currentObject.playbackSetting,
            position: SIMD3<Float>(0, 0, -0.3),
            orientation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        )

        storyManager.story.objects.append(centeredObject)

        return centeredObject
    }
    
    private func moveFrameLeft() {
        guard currentFrameIndex > 0 else { return }

        currentObject.frames.swapAt(currentFrameIndex, currentFrameIndex - 1)
        currentFrameIndex -= 1
    }

    private func moveFrameRight() {
        guard currentFrameIndex < currentObject.frames.count - 1 else { return }

        currentObject.frames.swapAt(currentFrameIndex, currentFrameIndex + 1)
        currentFrameIndex += 1
    }
    
    private func duplicateFrame() {
        guard currentFrameIndex < currentObject.frames.count else { return }

        let duplicatedFrame = currentObject.frames[currentFrameIndex]
        currentObject.frames.append(duplicatedFrame)
        currentFrameIndex = currentObject.frames.count - 1

        loadFrame(index: currentFrameIndex)
    }
    
    private func deleteFrame() {
        guard currentObject.frames.count > 1 else { return }

        currentObject.frames.remove(at: currentFrameIndex)

        if currentFrameIndex >= currentObject.frames.count {
            currentFrameIndex = max(0, currentFrameIndex - 1)
        }

        loadFrame(index: currentFrameIndex)
    }
    
    private func startPlayback() {
        stopPlayback()

        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { _ in
            Task { @MainActor in
                guard !currentObject.frames.isEmpty else { return }

                let totalFrames = currentObject.frames.count
                let currentFrame = currentFrameIndex

                switch currentObject.playbackSetting {
                case .loop:
                    let nextFrame = (currentFrame + 1) % totalFrames
                    currentFrameIndex = nextFrame
                    loadFrame(index: nextFrame)

                case .bounce:
                    let isAtStart = currentFrame == 0
                    let isAtEnd = currentFrame == totalFrames - 1
                    
                    if isAtStart && playbackDirection == -1 {
                        playbackDirection = 1
                    } else if isAtEnd && playbackDirection == 1 {
                        playbackDirection = -1
                    }
                    
                    let nextFrame = currentFrame + playbackDirection
                    currentFrameIndex = nextFrame
                    loadFrame(index: nextFrame)

                case .random:
                    var nextFrame: Int
                    repeat {
                        nextFrame = Int.random(in: 0..<totalFrames)
                    } while nextFrame == currentFrame
                    currentFrameIndex = nextFrame
                    loadFrame(index: nextFrame)
                }
            }
        }
    }
    
    private func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func closeOverlays() {
        showSettingsMenu = false
        showColorPicker = false
        showPlaybackSettingsMenu = false
        showFrameMenu = false
    }
}

struct Create3DView_Previews: PreviewProvider {
    static var previews: some View {
        Create3DView(navigationPath: .constant(NavigationPath()), storyManager: StoryManager())
            .previewDisplayName("Create 3D View")
            .previewInterfaceOrientation(.landscapeRight)
    }
}
