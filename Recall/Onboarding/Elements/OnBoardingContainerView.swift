//
//  OnBoardingContainerView.swift
//  Recall
//
//  Created by Brian Masse on 12/24/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - onBoardingSceneUIText
struct OnboardingSceneUIText {
    //goals
    static let goalSceneIntroductionText = "Goals represent achievements you want to work towards each week."
    static let goalSceneInstructionText = "Pick out some goals you want to work towards. You can always add, remove, or modify goals later "
    
    //tags
    static let tagSceneIntroductionText = "Tags categorize events on your calendar. Each is linked with one or more goals"
    static let tagSceneInstructionText = "Pick out tags for events you frequently do. You can always add, remove, or modify tags later"
    
//    events
    static let eventsSceneIntroductionText = "Events are the driver behind Recall."
    static let eventsSceneInstructionText = "This is a sample event, it contains lots of ways to help you better log and recall your memories"
    
    static let eventsTapAndHoldGestureInstruction = "You can tap and hold the calendar to quickly create an event"
    static let eventsContextMenuGestureInstruction = "You can long press on an event to see more options and take quick actions"
}

//MARK: OnboardingSceneView
protocol OnboardingSceneView {
    var sceneComplete: Binding<Bool> { get }
}

//MARK: - OnBoardingScene
//TODO: make goal + tag limits more apparent
enum OnBoardingScene: Int, CaseIterable {
    
    case goalTutorial
    case tagsTutorial
    case eventsTutorial
    case calendarTutorial
    
    case overview
    case howItWorks
    
    func incrementScene() -> OnBoardingScene {
        if let scene = OnBoardingScene(rawValue: self.rawValue + 1) { return scene }
        else { return self }
    }
    
    func decrementScene() -> OnBoardingScene {
        if let scene = OnBoardingScene(rawValue: self.rawValue - 1) { return scene }
        else { return self }
    }
}

//MARK: - OnBoardingContainerView
struct OnBoardingContainerView<C: View>: View {
    
    @State private var scene: OnBoardingScene = .goalTutorial
    @State private var sceneComplete: Bool = false
    
    @ViewBuilder
    private var sceneBuilder: ((OnBoardingScene, Binding<Bool>) -> C)
    
    private var onSubmit: (OnBoardingScene) -> Void
    
//    MARK: Init
    init(
        onSubmit: @escaping (OnBoardingScene) -> Void,
        @ViewBuilder contentBuilder: @escaping (OnBoardingScene, Binding<Bool>) -> C
    ) {
        self.sceneBuilder = contentBuilder
        self.onSubmit = onSubmit
    }
    
//    MARK: ContinueButton
    @ViewBuilder
    private func makeContinueButton() -> some View {
        UniversalButton {
            HStack {
                Spacer()
                
                RecallIcon("arrow.turn.down.right")
                
                UniversalText( "continue", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                
                Spacer()
            }
            .opacity(sceneComplete ? 1 : 0.25)
            .if(sceneComplete) { view in view.foregroundStyle(.black) }
            .rectangularBackground(style: sceneComplete ? .accent : .primary)
            .padding()
            
        } action: {
            if !self.sceneComplete { return }
            
            self.onSubmit(scene)
            
            self.scene = scene.incrementScene()
        }
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                sceneBuilder(scene, $sceneComplete)
                    .frame(width: geo.size.width, height: geo.size.height)
                
                makeContinueButton()
            }
        }
        .overlay { NoiseOverlay() }
        .background {
            OnBoardingBackgroundView()
        }
    }
}

//MARK: - OnboardingView
struct OnboardingView: View {

    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
//    MARK: Body
    var body: some View {
        OnBoardingContainerView(onSubmit: viewModel.onSubmit) { scene, sceneComplete in
            switch scene {
                
            case .calendarTutorial: OnboardingCalendarScene(sceneComplete: sceneComplete)
            case .goalTutorial: OnboardingGoalScene(sceneComplete: sceneComplete)
            case .tagsTutorial: OnboardingTagScene(sceneComplete: sceneComplete)
            case .eventsTutorial: OnboardingEventScene(sceneComplete: sceneComplete)
        
            default: EmptyView()
            }
        }
    }
}

#Preview {
    OnboardingView()
}
