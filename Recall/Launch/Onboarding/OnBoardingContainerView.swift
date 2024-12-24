//
//  OnBoardingContainerView.swift
//  Recall
//
//  Created by Brian Masse on 12/24/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: OnboardingSceneView
protocol OnboardingSceneView {
    var sceneComplete: Binding<Bool> { get }
}

//MARK: - OnBoardingScene
enum OnBoardingScene: Int, CaseIterable {
    
    case goalTutorial
    
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
        IconButton("arrow.forward",
                   label: "Continue",
                   fullWidth: true) { withAnimation {
            
            if !self.sceneComplete { return }
            
            self.onSubmit(scene)
            
            self.scene = scene.incrementScene()
        } }
                   .padding()
                   .opacity(sceneComplete ? 1 : 0.5)
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
        .background {
            OnBoardingBackgroundView()
        }
    }
}

//MARK: - OnboardingView
private struct OnboardingView: View {

    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
//    MARK: Body
    var body: some View {
        OnBoardingContainerView(onSubmit: viewModel.onSubmit) { scene, sceneComplete in
            switch scene {
            case .goalTutorial: OnboardingGoalScene(sceneComplete: sceneComplete)
            case .overview: Text("overview")
            case .howItWorks: Text("how it works")
            default: EmptyView()
            }
        }
    }
}

#Preview {
    OnboardingView()
}
