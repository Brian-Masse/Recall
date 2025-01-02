//
//  OnBoardingContainerView.swift
//  Recall
//
//  Created by Brian Masse on 12/24/24.
//

import Foundation
import SwiftUI
import UIUniversals


//MARK: - OnBoardingContainerView
struct OnboardingView: View {
    
    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
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
            .opacity(viewModel.sceneComplete ? 1 : 0.25)
            .if(viewModel.sceneComplete) { view in view.foregroundStyle(.black) }
            .rectangularBackground(style: viewModel.sceneComplete ? .accent : .primary)
            .padding()
            
        } action: { viewModel.incrementScene() }
    }
    
//    MARK: SceneBuilder
    @ViewBuilder
    private func sceneBuilder() -> some View {
        switch viewModel.scene {
          
        case .authentication:   OnboardingAuthenticationScene()
            
        case .goalTutorial:     OnboardingGoalScene()
        case .tagsTutorial:     OnboardingTagScene()
        case .eventsTutorial:   OnboardingEventScene()
        case .calendarTutorial: OnboardingCalendarScene()
    
        default: EmptyView()
        }
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                sceneBuilder()
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


#Preview {
    OnboardingView()
}
