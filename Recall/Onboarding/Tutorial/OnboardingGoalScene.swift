//
//  OnboardingGoalScene.swift
//  Recall
//
//  Created by Brian Masse on 12/28/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - TemplateGoal
struct TemplateGoal: Equatable, Identifiable {
    var id: String { title }
    
    let title: String
    let targetHours: Double
    let frequency: Int
    let priority: String
    let tagMask: TemplateTagMask
    
    init(
        _ title: String,
        targetHours: Double,
        frequency: RecallGoal.GoalFrequence,
        priority: RecallGoal.Priority,
        tagMask: TemplateTagMask
    ) {
        self.title = title
        self.targetHours = targetHours
        self.frequency = frequency.numericValue
        self.priority = priority.rawValue
        self.tagMask = tagMask
    }
}



//MARK: - onBoardingGoalScene
struct OnboardingGoalScene: View {
    
    @ObservedObject private var viewModel: OnboardingViewModel = OnboardingViewModel.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var templateCountString: String {
        "\(viewModel.selectedTemplateGoals.count) / \(viewModel.minimumGoalTemplates)"
    }
    
    private let goalTemplates: [TemplateGoal]
    
    init() {
        self.goalTemplates = TemplateManager().getGoalTemplates()
    }
    
//    MARK: makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        VStack(alignment: .leading) {
            HStack {
                UniversalText("Goals", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                
                Spacer()
                
                UniversalText(templateCountString,
                              size: Constants.UIDefaultTextSize,
                              font: Constants.mainFont)
            }
            
            UniversalText(OnboardingSceneUIText.goalSceneInstructionText,
                          size: Constants.UIDefaultTextSize,
                          font: Constants.mainFont)
            .opacity(0.75)
        }
    }
    
//    MARK: makeTemplateGoalSelector
    private func templateIsSelected(_ template: TemplateGoal) -> Bool {
        viewModel.selectedTemplateGoals.firstIndex(of: template) != nil
    }
    
    @ViewBuilder
    private func makeTemplateGoalSelector(_ templateGoal: TemplateGoal) -> some View {
        
        let templateIsSelected = templateIsSelected(templateGoal)
        
        UniversalText(templateGoal.title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            .highlightedBackground(templateIsSelected, disabledStyle: colorScheme == .light ? .primary : .transparent)
            .onTapGesture { withAnimation {
                viewModel.toggleTemplateGoal(templateGoal)
            } }
    }

//    MARK: makeTemplateGoalSelectors
    @ViewBuilder
    private func makeTemplateGoalSelectors() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            WrappedHStack(collection: goalTemplates, spacing: 7) { templateGoal in
                makeTemplateGoalSelector(templateGoal)
            }
            
        }
        .safeAreaPadding(.bottom, 100)
    }
    
//    MARK: Body
    var body: some View {
        
        OnboardingSplashScreenView(icon: "flag.pattern.checkered.2.crossed",
                                   title: "Goals",
                                   message: OnboardingSceneUIText.goalSceneIntroductionText) {
            VStack(alignment: .leading) {
                makeHeader()
                
                makeTemplateGoalSelectors()
                
                Spacer()
            }
            .padding(7)
            .overlay(alignment: .bottom) {
                OnboardingContinueButton(preTask: {
                    viewModel.goalSceneSubmitted(viewModel.selectedTemplateGoals)
                })
            }
            
            .onAppear {
                viewModel.checkInitialGoals()
            }
        }
    }
}


#Preview {
    OnboardingGoalScene()
}
