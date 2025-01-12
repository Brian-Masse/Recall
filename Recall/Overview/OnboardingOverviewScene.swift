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
              description: "Recall is a calendar app designed for remembering, recording, and saving all the events that go into your life"),
        
        .init(icon: "memories",
              description: "You can browse the events you log to look back on meaningful memories, remember important days, and celebrate progress"),
        
        .init(icon: "flag.pattern.checkered.2.crossed",
              description: "Recall also intelligently uses the events you record to accurately track your progress towards the goals you have set for yourself "),
        
        .init(icon: "checkmark.circle",
              description: "Recall keeps you present in the details of your life, while enabling you to look ahead to its future")
    ]
    
    private let howItWorksScenes: [OnboardingOverviewContainerView.OnboardingOverviewScene] = [
        .init(icon: "widget.small",
              description: "Each night you recall that day's events, including as much or as little information as you want"),
        
        .init(icon: "tag",
              description: "Each event gets tagged to easily group and color related events"),
        
            .init(icon: "flag.pattern.checkered.2.crossed",
                  description: "Goals use your events to record your progress and identify trends in your life"),
        
            .init(icon: "fireworks",
                  description: "Quickly setup a profile, and begin recalling your life")
        ]
    
    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
//    MARK: - Body
    var body: some View {
        
        if viewModel.scene == .overview {
            OnboardingOverviewContainerView(overviewScenes,
                                            splashScreen: .init(icon: "Calendar",
                                                                description: "What is Recall?"))
        } else if viewModel.scene == .howItWorks {
            OnboardingOverviewContainerView(howItWorksScenes,
                                            splashScreen: .init(icon: "gearshape.2",
                                                                description: "How does it work?"))
        }
        
    }
}

#Preview {
    OnboardingOverviewScene()
}
