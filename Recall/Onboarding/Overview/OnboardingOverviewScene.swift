//
//  OnboardingOverviewScene.swift
//  Recall
//
//  Created by Brian Masse on 1/9/25.
//

import Foundation
import SwiftUI
import UIUniversals


//MARK: - OnboardingOverviewScene
struct OnboardingOverviewScene: View {
    
    private let overviewScenes: [OnboardingOverviewContainerView.OnboardingOverviewScene] = [
        .init(icon: "calendar",
              description: "Recall is a calendar app designed for remembering the many events in your day"),
        
        .init(icon: "memories",
              description: "It helps you recall meaningful memories that otherwise get lost in the shuffle of daily life"),
        
        .init(icon: "flag.pattern.checkered.2.crossed",
              description: "It also intelligently combs through thousands of events, to reveal hard-to-find trends and insights."),
        
        .init(icon: "checkmark",
              description: "In short, Recall keeps you present in the details of your life, while helping you look towards to its future")
    ]
    
    private let howItWorksScenes: [OnboardingOverviewContainerView.OnboardingOverviewScene] = [
        .init(icon: "widget.small",
              description: "Each night you recall that day's events, including as much or as little information as you want"),
        
        .init(icon: "tag",
              description: "Each event gets tagged to easily group and color related events"),
        
            .init(icon: "flag.pattern.checkered.2.crossed",
                  description: "Goals then analyze those tags to identify progress and trends in your life"),
        
            .init(icon: "fireworks",
                  description: "Thats it! \n\nRecall is an easy tool that helps you find progress, success, and presence in your life.")
        ]
    
    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
    @State private var currentOverviewScene: Int = 0
    @State private var currentHowitWorksScene: Int = 0
    
    @State private var currentMaxTime: Double = 0
    
//    MARK: - Body
    var body: some View {
        
        if viewModel.scene == .overview {
            OnboardingOverviewContainerView(overviewScenes,
                                            currentSceneIndex: $currentOverviewScene,
                                            textBackground: true,
                                            splashScreen: .init(icon: "Calendar",
                                                                description: "What is Recall?"))
            .task {
                await RecallModel.wait(for: 3)
                currentMaxTime = 4 * OnboardingOverviewEventAnimation.animationDelay
            }
            .onChange(of: currentOverviewScene) {
                if currentOverviewScene == overviewScenes.count - 1 { withAnimation { currentMaxTime = 0 } }
                else { currentMaxTime = Double(currentOverviewScene + 1) * 4 * OnboardingOverviewEventAnimation.animationDelay }
            }
            .background {
                OnboardingOverviewEventAnimation(currentMaxTime: $currentMaxTime)
            }
            
        }
//        else if viewModel.scene == .howItWorks {
//            OnboardingOverviewContainerView(howItWorksScenes,
//                                            currentSceneIndex: $currentHowitWorksScene,
//                                            splashScreen: .init(icon: "gearshape.2",
//                                                                description: "How does it work?"))
//        }
    }
}

#Preview {
    OnboardingOverviewScene()
}
