//
//  TutorialViews.swift
//  Recall
//
//  Created by Brian Masse on 8/28/23.
//

import Foundation
import SwiftUI


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
        case complete
        
        enum BroadScene: String, CaseIterable, Identifiable {
            case goal = "Goals"
            case tag = "Tags"
            case event = "Events"
            
            var id: String {
                self.rawValue
            }
        }
        
        private func getScene(from value: Int) -> TutorialViews.TutorialScene {
            TutorialScene(rawValue: value) ?? .goalCreation
        }
        
        func advanceScene() -> TutorialScene {
            getScene(from:  self.rawValue + 1 )
        }
    
        func returnScene(in activeBroadScene: BroadScene) -> TutorialScene {
            getScene(from: max( self.rawValue - 1, getScenesBefore(activeBroadScene) + 1) )
        }
        
        private func getBroadSceneTotal(_ scene: BroadScene) -> Double {
            switch scene {
            case .goal: return 4
            case .tag: return 4
            default: return 1
            }
        }
        
        private func getScenesBefore(_ activeBroadScene: BroadScene) -> Int {
            switch activeBroadScene {
            case .goal: return 0
            case .tag: return Int(getBroadSceneTotal(.goal))
            default: return 0
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
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeHeader() -> some View {
        ZStack {
            HStack {
                if scene.rawValue >= 1 {
                    Group {
                        Image(systemName: "arrow.backward")
                        UniversalText( "back", size: Constants.UIDefaultTextSize, font: Constants.mainFont, lighter: true )
                    }.onTapGesture { withAnimation { scene = scene.returnScene(in: broadScene) }}
                }
                
                Spacer()
                
                Group {
                    UniversalText( "skip", size: Constants.UIDefaultTextSize, font: Constants.mainFont, lighter: true )
                    Image(systemName: "arrow.forward")
                }.onTapGesture { showSkipTutorialWarning = true }
            }
            .opacity(0.5)
            
            UniversalText(broadScene.rawValue, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
        }
    }
    
    @ViewBuilder
    private func makeBody() -> some View {
        
        VStack {
            switch broadScene {
            case .goal:     GoalCreationScene(scene: $scene, broadScene: $broadScene, nextButtonIsActive: $nextButtonIsActive)
            case .tag:      TagsCreationScene(scene: $scene, broadScene: $broadScene, nextButtonIsActive: $nextButtonIsActive)
            case .event: EmptyView()
            }
    
            Spacer()
            
            ConditionalLargeRoundedButton(title: "continue", icon: "arrow.forward", condition: { nextButtonIsActive }) {
                scene = scene.advanceScene()
                nextButtonIsActive = false
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
        .defaultAlert($showSkipTutorialWarning, title: "Skip tutorial?", description: "")
        
    }
}
