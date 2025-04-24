//
//  StoryView.swift
//  Scribble
//
//  Created by Kyle Graham on 13/12/2024.
//

import SwiftUI

struct StoryView: View {
    @StateObject var storyManager = StoryManager()
    @State private var navigationPath = NavigationPath()
    @State private var isExporting = false
    @State private var isShowingObjectList = false
    @State private var isShowingObjectMoreList = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedObject: Object? = nil
    @State private var isRenamingObject = false
    @State private var isDeletingObject = false
    @State private var newName = ""
    @State private var isPlaying = false
    @State private var playbackTimer: Timer?
    @State private var playbackSpeedIndex = 2
    @State private var showHelp: Bool = false
    @State private var shareItem: ShareItem?
    @AppStorage("animateObjectsButton") private var animateObjectsButton: Bool = true
    
    private var playbackSpeed: TimeInterval {
        switch playbackSpeedIndex {
        case 0: return 1.125    // Slow     (1.125 seconds per frame)
        case 1: return 0.9375   // Slower   (0.9375 seconds per frame)
        case 2: return 0.75     // Normal   (0.75 seconds per frame)
        case 3: return 0.5625   // Fast     (0.5625 seconds per frame)
        case 4: return 0.375    // Fastest  (0.375 seconds per frame)
        default: return 0.75    // Default  (normal speed)
        }
    }
    
    private let playbackSpeeds = [
        "gauge.with.dots.needle.0percent",
        "gauge.with.dots.needle.33percent",
        "gauge.with.dots.needle.50percent",
        "gauge.with.dots.needle.67percent",
        "gauge.with.dots.needle.100percent"
    ]
    
    var helpItems = [
        HelpItem(symbol: "move.3d", heading: "Reposition", body: "Move all objects in your story at once using the reposition button"),
        HelpItem(symbol: "square.2.layers.3d.bottom.filled", heading: "Manage", body: "Easily create, rename, reposition, duplicate, and delete objects in the object list"),
        HelpItem(symbol: "play", heading: "Watch", body: "See your story come to life and adjust its playback speed using the playback buttons"),
        HelpItem(symbol: "square.and.arrow.up", heading: "Share", body: "Easily export your story and share it with others using the share button")
    ];

    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                ARViewContainer(storyManager: storyManager, isRepositioning: $storyManager.isRepositioning)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        restartARSession()
                    }
                    .onDisappear {
                        pauseARSession()
                    }
                
                VStack {
                    HStack {
                        ButtonComponent(text: "Reposition", symbol: "move.3d", isEnabled: !storyManager.isRepositioning, action: {
                            storyManager.startRepositioningAll()
                            isShowingObjectList = false
                        })
                        
                        ButtonComponent(symbol: "questionmark", isEnabled: !storyManager.isRepositioning, isWide: true) {
                            showHelp = true
                        }
                        .frame(width: 60, height: 40)
                        
                        Spacer()
                
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(width: 60, height: 40)
                        } else {
                            ButtonComponent(symbol: "square.and.arrow.up", isEnabled: !storyManager.isRepositioning, action: {
                                isExporting = true

                                Task {
                                    let usdzURL = storyManager.exportToUSDZ()

                                    if let usdzURL = usdzURL {
                                        shareItem = ShareItem(items: [usdzURL])
                                    } else {
                                        print("Failed to generate USDZ file")
                                    }
                                    isExporting = false
                                }
                            })
                            .frame(width: 60, height: 40)
                            .popover(item: $shareItem, arrowEdge: .top) { item in
                                ActivityViewController(activityItems: item.items)
                            }
                        }
                        
                        ButtonComponent(text: "\(storyManager.story.objects.count)", symbol: "square.2.layers.3d.bottom.filled", isEnabled: !storyManager.isRepositioning, animatedBorder: animateObjectsButton) {
                            isShowingObjectList.toggle()
                            isShowingObjectMoreList = false
                            selectedObject = nil
                            animateObjectsButton = false
                        }
                    }
                    .padding(.top, UIDevice.current.userInterfaceIdiom == .phone ? 50 : 0)
                    
                    Spacer()
                    
                    HStack {
                        ButtonComponent(symbol: playbackSpeeds[playbackSpeedIndex], isCircular: true, isEnabled: !storyManager.isRepositioning, action: {
                            playbackSpeedIndex = (playbackSpeedIndex + 1) % playbackSpeeds.count
                            
                            if isPlaying {
                                startPlayback()
                            }
                        })
                        
                        ButtonComponent(text: isPlaying ? "Pause" : "Play", symbol: isPlaying ? "pause" : "play", isEnabled: !storyManager.isRepositioning) {
                            if isPlaying {
                                stopPlayback()
                            } else {
                                startPlayback()
                            }
                            isPlaying.toggle()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 30)
                
                if storyManager.isRepositioning {
                    VStack {
                        TextComponent(text: "Tap Anywhere to Place", fontStyle: .title3, isBold: true)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 150 : 80)
                }
                
                if isShowingObjectList {
                    VStack {
                        HStack {
                            Spacer()
                            
                            ObjectListView(
                                storyManager: storyManager,
                                onMoreButtonPressed: { object in
                                    if selectedObject?.id == object.id && isShowingObjectMoreList {
                                        isShowingObjectMoreList = false
                                        selectedObject = nil
                                    } else {
                                        selectedObject = object
                                        isShowingObjectMoreList = true
                                    }
                                },
                                onCreatePressed: {
                                    selectedObject = nil
                                    isShowingObjectList = false
                                    isShowingObjectMoreList = false
                                    navigationPath.append("CreateSelectionView")
                                },
                                selectedObject: $selectedObject
                            )
                            .offset(x: -10, y: UIDevice.current.userInterfaceIdiom == .phone ? 120 : 70)
                            .foregroundStyle(Color.background_alt)
                            .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 250 : 300, height: 450)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 30)
                }
                
                if isShowingObjectMoreList, selectedObject != nil {
                    VStack {
                        HStack {
                            Spacer()
                            
                            ObjectMoreListView(
                                onRenameTapped: {
                                    if let object = selectedObject {
                                        newName = object.name
                                        isRenamingObject = true
                                    }
                                },
                                onRepositionTapped: {
                                    if let object = selectedObject {
                                        storyManager.startRepositioningObject(object)
                                        isShowingObjectList = false
                                        selectedObject = nil
                                    }
                                },
                                onDuplicateTapped: {
                                    let duplicatedObject = storyManager.duplicateObject(selectedObject!)
                                    storyManager.startRepositioningObject(duplicatedObject)
                                    isShowingObjectList = false
                                    selectedObject = nil
                                },
                                onDeleteTapped: {
                                    isDeletingObject = true
                                }
                            )
                            .offset(x: UIDevice.current.userInterfaceIdiom == .phone ? -240 : -330, y: UIDevice.current.userInterfaceIdiom == .phone ? 120 : 70)
                            .foregroundStyle(Color.background_alt)
                            .frame(width: 140)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 30)
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "CreateSelectionView" {
                    CreateSelectionView(navigationPath: $navigationPath, storyManager: storyManager)
                } else if value == "Create2DView" {
                    Create2DView(navigationPath: $navigationPath, storyManager: storyManager)
                } else if value == "Create3DView" {
                    Create3DView(navigationPath: $navigationPath, storyManager: storyManager)
                }
            }
            .alert("Rename Object", isPresented: $isRenamingObject) {
                TextField("Beach Umbrella", text: $newName)
                
                Button("Save") {
                    if let object = selectedObject {
                        storyManager.renameObject(object, newName: newName)
                    }
                    isRenamingObject = false
                    selectedObject = nil
                }
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Cancel", role: .cancel) {
                    isRenamingObject = false
                    selectedObject = nil
                }
            }
            .alert("Delete Object", isPresented: $isDeletingObject, actions: {
                Button("Delete", role: .destructive) {
                    if selectedObject != nil {
                        storyManager.deleteObject(selectedObject!)
                        isShowingObjectMoreList = false
                        selectedObject = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    isShowingObjectMoreList = false
                    selectedObject = nil
                }
            }, message: {
                Text("This action is permanent (cannot be undone).")
            })
            .ignoresSafeArea()
            .sheet(isPresented: $showHelp) {
                HelpComponent(title: "Getting Started", helpItems: helpItems) {
                    showHelp = false
                    UserDefaults.standard.set(false, forKey: "showStoryHelp")
                }
            }
            .onAppear {
                if UserDefaults.standard.bool(forKey: "showStoryHelp") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showHelp = true
                    }
                }
            }
        }
    }
    
    private func startPlayback() {
        playbackTimer?.invalidate()
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: playbackSpeed, repeats: true) { _ in
            Task { @MainActor in
                for object in storyManager.story.objects {
                    guard !object.frames.isEmpty else { continue }
                    
                    let currentFrame = object.activeFrameIndex
                    let totalFrames = object.frames.count
                    
                    switch object.playbackSetting {
                    case .loop:
                        let nextFrame = (currentFrame + 1) % totalFrames
                        storyManager.setActiveFrame(for: object.id, to: nextFrame)
                        
                    case .bounce:
                        let isAtStart = currentFrame == 0
                        let isAtEnd = currentFrame == totalFrames - 1
                        
                        if isAtStart && object.direction == -1 {
                            storyManager.setPlaybackDirection(for: object.id, to: 1)
                            let nextFrame = currentFrame + 1
                            storyManager.setActiveFrame(for: object.id, to: nextFrame)
                        } else if isAtEnd && object.direction == 1 {
                            storyManager.setPlaybackDirection(for: object.id, to: -1)
                            let nextFrame = currentFrame - 1
                            storyManager.setActiveFrame(for: object.id, to: nextFrame)
                        } else {
                            let nextFrame = currentFrame + object.direction
                            storyManager.setActiveFrame(for: object.id, to: nextFrame)
                        }
                        
                    case .random:
                        var nextFrame: Int
                        repeat {
                            nextFrame = Int.random(in: 0..<totalFrames)
                        } while nextFrame == currentFrame
                        storyManager.setActiveFrame(for: object.id, to: nextFrame)
                    }
                }
            }
        }
    }
    
    private func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func pauseARSession() {
        ARCoordinator.shared?.pauseSession()
    }

    private func restartARSession() {
        ARCoordinator.shared?.restartSession()
    }
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView()
            .previewDisplayName("Story View")
            .previewInterfaceOrientation(.landscapeRight)
    }
}
