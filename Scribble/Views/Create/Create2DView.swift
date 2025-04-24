//
//  Create2DView.swift
//  Scribble
//
//  Created by Kyle Graham on 31/1/2025.
//

import SwiftUI
import simd

struct Create2DView: View {
    @Binding var navigationPath: NavigationPath
    @State private var isDrawing: Bool = true
    @State private var shapeName: String = ""
    @State private var selectedColor: Color = .red
    @State private var selectedThickness: CGFloat = 20
    @State private var showColorPicker: Bool = false
    @State private var showSettingsMenu: Bool = false
    @State private var showPlaybackSettingsMenu: Bool = false
    @State private var showFrameMenu: Bool = false
    @State private var showGrid: Bool = UserDefaults.standard.bool(forKey: "showGrid2D")
    @State private var gridSpacing: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "gridSpacing2D"))
    @State private var strokeResolution: Double = UserDefaults.standard.double(forKey: "strokeResolution2D")
    @State private var isPlaying = false
    @State private var showClearAlert: Bool = false
    @State private var showContinueAlert: Bool = false
    @State private var currentFrameIndex: Int = 0
    @State private var currentObject: Object
    @State private var playbackTimer: Timer?
    @State private var playbackDirection: Int = 1
    @State private var showHelp: Bool = false
    @StateObject private var drawingViewModel = DrawingViewModel()
    var storyManager: StoryManager
    
    init(navigationPath: Binding<NavigationPath>, storyManager: StoryManager) {
        _navigationPath = navigationPath
        self.storyManager = storyManager

        _currentObject = State(initialValue: Object(
            name: "New Object",
            frames: [Frame(strokes: [])],
            playbackSetting: .loop,
            position: SIMD3<Float>(0, 0, -0.3),
            orientation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        ))
    }
    
    var helpItems = [
        HelpItem(symbol: "pencil.and.scribble", heading: "Draw", body: "Sketch your creation while adjusting stroke colour and thickness"),
        HelpItem(symbol: "rectangle.portrait.arrowtriangle.2.outward", heading: "Animate", body: "Build multiple frames, tweak playback settings, and see your work come to life"),
        HelpItem(symbol: "beziercurve", heading: "Adjust", body: "Control the maximum number of nodes (turns) strokes have by modifying the stroke resolution"),
        HelpItem(symbol: "hand.tap", heading: "Organise", body: "Tap a frame to select it, then tap again to rearrange, duplicate, or delete it")
    ];
    
    var body: some View {
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
                
                ButtonComponent(text: "Continue", foregroundColor: Color.accentColor, isEnabled: !drawingViewModel.strokes.isEmpty) {
                    closeOverlays()
                    showContinueAlert = true
                }
                .alert("Name Object", isPresented: $showContinueAlert) {
                    TextField("Umbrella", text: $shapeName)
                    Button("Cancel", role: .cancel) {}
                    Button("Continue") {
                        let newObject = saveDrawingAs3DObject(named: shapeName.isEmpty ? "Unnamed Shape" : shapeName)
                        storyManager.startRepositioningObject(newObject)
                        navigationPath.removeLast(2)
                    }
                    .disabled(shapeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            
            Spacer()
            
            ZStack {
                GeometryReader { geometry in
                    ZStack {
                        Color.canvas
                            .contentShape(Rectangle())
                            .clipShape(RoundedRectangle(cornerRadius: 10.0))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if geometry.frame(in: .local).contains(value.location) {
                                            closeOverlays()
                                            drawingViewModel.addPoint(value.location, color: selectedColor, thickness: selectedThickness, isErasing: !isDrawing)
                                        }
                                    }
                                    .onEnded { _ in
                                        if isDrawing {
                                            drawingViewModel.endStroke()
                                            saveFrame(index: currentFrameIndex)
                                        }
                                    }
                            )

                        if showGrid {
                            drawGrid(in: geometry.size, spacing: gridSpacing)
                        }

                        if currentFrameIndex > 0 {
                            ForEach(currentObject.frames[currentFrameIndex - 1].strokes) { stroke in
                                let fadedStroke = Drawing2DStroke(
                                    points: stroke.points.map { CGPoint(x: $0.x, y: $0.y) },
                                    color: Color.gray.opacity(0.4),
                                    thickness: selectedThickness
                                )
                                drawingViewModel.renderStroke(fadedStroke, resolution: Int(strokeResolution))
                            }
                        }

                        ForEach(drawingViewModel.tempStrokes) { stroke in
                            drawingViewModel.renderStroke(stroke, resolution: Int(1000.0))
                        }

                        ForEach(drawingViewModel.strokes) { stroke in
                            drawingViewModel.renderStroke(stroke, resolution: Int(strokeResolution))
                        }
                    }
                }
                .padding(.leading, 75)
                
                HStack {
                    VStack {
                        ButtonComponent(symbol: isDrawing ? "pencil" : "eraser", isCircular: true, action: {
                            closeOverlays()
                            isDrawing.toggle()
                        })
                        .frame(width: 60, height: 60)
                        .padding(.bottom, 10)
                        
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

                        ButtonComponent(symbol: "arrow.uturn.backward", isCircular: true, isEnabled: drawingViewModel.canUndo, action: {
                            closeOverlays()
                            drawingViewModel.undo()
                            saveFrame(index: currentFrameIndex)
                        })
                        .padding(.top, 40)
                        .padding(.bottom, 10)

                        ButtonComponent(symbol: "arrow.uturn.forward", isCircular: true, isEnabled: drawingViewModel.canRedo, action: {
                            closeOverlays()
                            drawingViewModel.redo()
                            saveFrame(index: currentFrameIndex)
                        })

                        ButtonComponent(symbol: "trash", isCircular: true, isEnabled: drawingViewModel.hasStrokes, action: {
                            closeOverlays()
                            showClearAlert = true
                        })
                        .padding(.top, 40)
                        .alert("Clear all strokes?", isPresented: $showClearAlert) {
                            Button("Clear All", role: .destructive) {
                                drawingViewModel.clearAll()
                                saveFrame(index: currentFrameIndex)
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This action will permanently remove all strokes and cannot be undone.")
                        }
                    }
                    .frame(width: 60)
                    Spacer()
                }

                if showSettingsMenu {
                    VStack {
                        HStack {
                            CreateSettings2DView(showGrid: $showGrid, gridSpacing: $gridSpacing, strokeResolution: $strokeResolution)
                                .padding(.leading, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 100)
                                .offset(y: -15)
                            Spacer()
                        }
                        Spacer()
                    }
                }

                if showColorPicker {
                    HStack {
                        ColorPickerComponent(selectedColor: $selectedColor, selectedThickness: $selectedThickness)
                            .padding(.leading, UIDevice.current.userInterfaceIdiom == .phone ? 20 : 75)
                            .offset(y: -108)
                        Spacer()
                    }
                }
                
                if showPlaybackSettingsMenu {
                    VStack {
                        Spacer()
                        HStack {
                            CreatePlaybackSettingsView(playbackSetting: $currentObject.playbackSetting)
                                .offset(x: 99, y: 15)
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
                        .offset(y: 15)
                    }
                }
            }
            .padding(.vertical)

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
                                            saveFrame(index: currentFrameIndex)
                                            if currentFrameIndex == index {
                                                showFrameMenu.toggle()
                                            } else {
                                                currentFrameIndex = index
                                                loadFrame(index: index)
                                            }
                                        }
                                        .scaleEffect(y: -1)
                                }
                                if drawingViewModel.hasStrokes {
                                    RoundedRectangle(cornerRadius: 10.0)
                                        .fill(Color.white)
                                        .frame(width: 60, height: 40)
                                        .overlay {
                                            Image(systemName: "plus")
                                                .font(.title2)
                                        }
                                        .onTapGesture {
                                            closeOverlays()
                                            saveFrame(index: currentFrameIndex)
                                            currentObject.frames.append(Frame(strokes: []))
                                            currentFrameIndex = currentObject.frames.count - 1
                                            drawingViewModel.clearAll()
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
        .background(Color.background)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showHelp) {
            HelpComponent(title: "Drawing in 2D (In-Place)", helpItems: helpItems) {
                showHelp = false
                UserDefaults.standard.set(false, forKey: "show2DHelp")
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "show2DHelp") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showHelp = true
                }
            }
        }
    }

    private func drawGrid(in size: CGSize, spacing: CGFloat) -> some View {
        Path { path in
            let centerX = size.width / 2
            let centerY = size.height / 2

            for x in stride(from: centerX, to: size.width, by: spacing) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for x in stride(from: centerX, through: 0, by: -spacing) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: centerY, to: size.height, by: spacing) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            for y in stride(from: centerY, through: 0, by: -spacing) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
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
    
    private func saveFrame(index: Int) {
        guard !drawingViewModel.strokes.isEmpty else { return }

        let strokes = drawingViewModel.strokes.map { drawingStroke in
            Stroke(
                points: drawingStroke.points.map { point in
                    Point(x: point.x, y: point.y, z: 0)
                },
                color: CodableColor(from: UIColor(drawingStroke.color)),
                thickness: drawingStroke.thickness
            )
        }

        if index < currentObject.frames.count {
            currentObject.frames[index] = Frame(strokes: strokes)
        } else {
            currentObject.frames.append(Frame(strokes: strokes))
        }
    }

    private func loadFrame(index: Int) {
        drawingViewModel.clearAll()
        let strokes = currentObject.frames[index].strokes.map { stroke in
            Drawing2DStroke(
                points: stroke.points.map { CGPoint(x: $0.x, y: $0.y) },
                color: Color(stroke.color.toUIColor()),
                thickness: stroke.thickness
            )
        }
        drawingViewModel.strokes = strokes
    }
    
    private func saveDrawingAs3DObject(named name: String) -> Object {
        guard !currentObject.frames.isEmpty else { fatalError("No frames to save.") }

        var newObject = currentObject
        newObject.name = name

        let allPoints = newObject.frames.flatMap { $0.strokes }.flatMap { $0.points }
        guard let minX = allPoints.map({ $0.x }).min(),
              let maxX = allPoints.map({ $0.x }).max(),
              let minY = allPoints.map({ $0.y }).min(),
              let maxY = allPoints.map({ $0.y }).max() else {
            fatalError("Could not compute bounding box.")
        }

        let width = maxX - minX
        let height = maxY - minY
        let scaleFactor: CGFloat = 0.0005

        let scaledFrames = newObject.frames.map { frame in
            Frame(strokes: frame.strokes.map { stroke in
                Stroke(
                    points: stroke.points.map { point in
                        Point(
                            x: (point.x - minX - width / 2) * scaleFactor,
                            y: -(point.y - minY - height / 2) * scaleFactor,
                            z: 0
                        )
                    },
                    color: stroke.color,
                    thickness: stroke.thickness
                )
            })
        }

        newObject.frames = scaledFrames
        newObject.position = SIMD3<Float>(0, 0, -0.3)
        newObject.orientation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))

        storyManager.story.objects.append(newObject)
        
        return newObject
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
        showFrameMenu = false
        showPlaybackSettingsMenu = false
    }
}

struct Create2DView_Previews: PreviewProvider {
    static var previews: some View {
        Create2DView(navigationPath: .constant(NavigationPath()), storyManager: StoryManager())
            .previewDisplayName("Create 2D View")
            .previewInterfaceOrientation(.landscapeRight)
    }
}
