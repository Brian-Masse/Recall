//
//  TutorialViews.swift
//  Recall
//
//  Created by Brian Masse on 8/28/23.
//

import Foundation
import SwiftUI


//MARK: ViewModifiers

private struct ConstrainedBroadScene: ViewModifier {
    
    let broadScene: TutorialViews.TutorialScene.BroadScene
    
    @Binding var activeScene: TutorialViews.TutorialScene
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                
                let bounds = activeScene.getValidSceneBounds(for: broadScene)
                if activeScene.rawValue < bounds.0 { activeScene = activeScene.setScene(to: bounds.0) }
                if activeScene.rawValue > bounds.1 { activeScene = activeScene.setScene(to: bounds.1) }
            }
    }
}

extension View {
    
    func constrainBroadScene( to broadScene: TutorialViews.TutorialScene.BroadScene, activeScene: Binding<TutorialViews.TutorialScene> ) -> some View  {
        modifier( ConstrainedBroadScene(broadScene: broadScene, activeScene: activeScene) )
    }
    
}

struct TutorialViews: View {
    
//    MARK: Scenes
    enum TutorialScene: Int {    
        case goalCreation
        case goalName
        case goalPurpose
        case goalTiming
        case goalView
        
        case tagCreation
        case tagName
        case tagColor
        case tagGoal
        case tagView
        
        case eventCreation
        case eventName
        case eventNotes
        case eventTime
        case eventTag
        case eventGoals
        case eventView
        
        case complete
        
        enum BroadScene: String, CaseIterable, Identifiable {
            case goal = "Goals"
            case tag = "Tags"
            case event = "Events"
            
            var id: String {
                self.rawValue
            }
        }
//        MARK: Convenience functions for scenes
        private func getScene(from value: Int) -> TutorialViews.TutorialScene {
            TutorialScene(rawValue: value) ?? .goalCreation
        }
    
        func advanceScene() -> TutorialScene {
            getScene(from:  self.rawValue + 1 )
        }
    
        func returnScene(in activeBroadScene: BroadScene) -> TutorialScene {
            getScene(from: max( self.rawValue - 1, getScenesBefore(activeBroadScene)) )
        }
        
        func setScene(to index: Int) -> TutorialScene {
            TutorialScene(rawValue: index) ?? .goalCreation
        }
        
//        The following three functions are used to switch the broad scenes automatically, and to ensure a valid view is always being displayed
//        This function says what indecies of this scene list are valid for a given broad scene
        func getValidSceneBounds(for broadScene: BroadScene) -> (Int, Int) {
            (getScenesBefore(broadScene), getScenesBefore(broadScene) + Int(getBroadSceneTotal(broadScene)) )
        }
        
//        This is the number of sub scenes in a given broad scene
        private func getBroadSceneTotal(_ scene: BroadScene) -> Double {
            switch scene {
            case .goal: return 4
            case .tag: return 4
            case .event: return 6
            }
        }
        
//        this counts how many subscenes occour before the start of a given broad scene
        private func getScenesBefore(_ activeBroadScene: BroadScene) -> Int {
            switch activeBroadScene {
            case .goal: return 0
            case .tag: return Int(getBroadSceneTotal(.goal)) + 1
            default: return Int(getBroadSceneTotal(.goal) + getBroadSceneTotal(.tag))  + 2
            }
        }
        
        func getBroadSceneProgress(from activeBroadScene: BroadScene) -> Double {
            let difference = getScenesBefore(activeBroadScene)
            let total = getBroadSceneTotal(activeBroadScene)
            return Double( self.rawValue - difference ) / total
        }
        
        func checkBroadSceneCompletion(from activeBroadScene: BroadScene) -> Bool {
            self.rawValue >= Int(getBroadSceneTotal(activeBroadScene)) + getScenesBefore(activeBroadScene)
        }
    }
    

//    MARK: Vars
    
    @Binding var page: ContentView.EntryPage
    
    @State private var scene: TutorialViews.TutorialScene = .goalCreation
    @State private var broadScene: TutorialViews.TutorialScene.BroadScene = .goal
    
    @State var nextButtonIsActive: Bool = false
    @State var showSkipTutorialWarning: Bool = false
    
    private func progressScene(to passedScene: TutorialScene? = nil) {
        if passedScene == nil { scene = scene.advanceScene() }
        else { scene = passedScene! }
        
        let bounds = scene.getValidSceneBounds(for: broadScene)
        if scene.rawValue > bounds.1 {
            switch broadScene {
            case .goal: broadScene = .tag
            case .tag: broadScene = .event
            case .event: page = .app
            }
            
            if scene == .complete {
                RecallModel.index.finishTutorial()
                page = .app
            }
        }
                    
        nextButtonIsActive = false
    }
    
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeHeader() -> some View {
        ZStack {
            HStack {
                if scene.rawValue >= 1 {
                    Group {
                        Image(systemName: "arrow.backward")
                        UniversalText( "back", size: Constants.UIDefaultTextSize, font: Constants.mainFont, lighter: true )
                    }
                    .opacity(0.5)
                    .onTapGesture { withAnimation { scene = scene.returnScene(in: broadScene) }}
                }
                
                Spacer()
                
                HStack {
                    UniversalText( "skip", size: Constants.UIDefaultTextSize, font: Constants.mainFont, lighter: true )
                    Image(systemName: "arrow.forward")
                }
                .opacity(0.5)
                .onTapGesture { showSkipTutorialWarning = true }
            }
            
            UniversalText(broadScene.rawValue, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
        }
    }
    
    @ViewBuilder
    private func makeBody() -> some View {
        
        VStack {
            switch broadScene {
            case .goal:     GoalCreationScene(scene: $scene,
                                              broadScene: $broadScene,
                                              nextButtonIsActive: $nextButtonIsActive).constrainBroadScene(to: .goal, activeScene: $scene)
            case .tag:      TagsCreationScene(scene: $scene,
                                              broadScene: $broadScene,
                                              nextButtonIsActive: $nextButtonIsActive).constrainBroadScene(to: .tag, activeScene: $scene)
            case .event:    EventsCreationScene(scene: $scene,
                                              broadScene: $broadScene,
                                              nextButtonIsActive: $nextButtonIsActive).constrainBroadScene(to: .event, activeScene: $scene)
            }
    
            Spacer()
            
//        MARK: Next Button
//            This button also checks to make sure that when a new broad scene is ready, the view switches to it
            
            let title = scene == .eventView ? "continue to Recall" : "continue"
            ConditionalLargeRoundedButton(title: title, icon: "arrow.forward", condition: { nextButtonIsActive }) {
                progressScene()
            }
        }
    }
    
    @ViewBuilder
    private func makeProgressNode(for passedScene: TutorialViews.TutorialScene.BroadScene) -> some View {
        
        if passedScene == broadScene {
            let progress = scene.getBroadSceneProgress(from: passedScene)
            
            ZStack(alignment: .leading) {
                
                Rectangle()
                    .cornerRadius(Constants.UIDefaultCornerRadius)
                    .universalTextStyle()
                    .opacity(0.2)
                    .frame(width: 50, height: 10)
                
                Rectangle()
                    .cornerRadius(Constants.UIDefaultCornerRadius)
                    .universalForegroundColor()
                    .frame(width: 50 * progress, height: 10)
            }
            
        } else {
            Circle()
                .if( scene.checkBroadSceneCompletion(from: passedScene)) { view in view.universalForegroundColor() }
                .if( !scene.checkBroadSceneCompletion(from: passedScene)) { view in
                    view
                        .universalTextStyle()
                        .opacity(0.2)
                }
                .frame(width: 10, height: 10)
        }
    }
    
    @ViewBuilder
    private func makeProgressView() -> some View {
        HStack {
            ForEach(TutorialScene.BroadScene.allCases) { scene in
                
                makeProgressNode(for: scene)
                
            }
        }
    }

    
//    MARK: Body
    var body: some View {
        VStack {
            makeHeader()
            makeProgressView()
                .padding(.bottom)
            
            makeBody()
            
        }
        .padding(7)
        .padding(.bottom, 30)
        .universalBackground()
        .alert("Skip tutorial?", isPresented: $showSkipTutorialWarning) {
            Button("skip") { progressScene(to: .complete) }
            Button(role: .cancel) { } label: {
                Text("cancel")
            }

        }
    }
}
