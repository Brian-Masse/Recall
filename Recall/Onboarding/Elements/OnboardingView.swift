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
    
//    MARK: SceneBuilder
    @ViewBuilder
    private func sceneBuilder() -> some View {
        switch viewModel.scene {
          
        case .authentication:   OnboardingAuthenticationScene()
        case .profileSetup1:    OnboardingProfileCreationScene()
            
        case .goalTutorial:         OnboardingGoalScene()
        case .tagsTutorial:         OnboardingTagScene()
        case .eventsTutorial:       OnboardingEventScene()
        case .calendarTutorial1:    OnboardingCalendarAnimationHandler()
        case .calendarTutorial2:    OnboardingCalendarScene()
    
        default: EmptyView()
        }
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            sceneBuilder()
                .padding(7)
        }
        .overlay { NoiseOverlay() }
        .background {
            OnBoardingBackgroundView()
            FullScreenProgressBar(progress: viewModel.currentSceneProgress)
                .universalStyledBackgrond(.accent, onForeground: true)
        }
    }
}


#Preview {
    OnboardingView()
}
