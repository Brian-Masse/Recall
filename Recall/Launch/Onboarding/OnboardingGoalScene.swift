//
//  OnboardingGoalScene.swift
//  Recall
//
//  Created by Brian Masse on 12/28/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - onBoardingSceneUIText
struct OnboardingSceneUIText {
    static let goalSceneInstructionText1 = "Pick out some goals you want to work towards. You can always add, remove, or modify goals later "
}

//MARK: - TemplateGoal
struct TemplateGoal: Equatable, Identifiable {
    var id: String { title }
    
    let title: String
    let targetHours: Double
    let frequency: Int
    let priority: String
    
    init(
        _ title: String,
        targetHours: Double,
        frequency: RecallGoal.GoalFrequence,
        priority: RecallGoal.Priority
    ) {
        self.title = title
        self.targetHours = targetHours
        self.frequency = frequency.numericValue
        self.priority = priority.rawValue
    }
}

//MARK: templateGoals
private let templateGoals: [TemplateGoal] = [
    .init( "Read a book",    targetHours: 1, frequency: .daily, priority: .low ),
    .init( "Productvity",    targetHours: 35, frequency: .weekly, priority: .high),
    .init( "Go for a walk",  targetHours: 1, frequency: .daily, priority: .medium ),
    .init( "Workout",        targetHours: 7, frequency: .weekly, priority: .high )
]

//MARK: - onBoardingGoalScene
struct OnboardingGoalScene: View, OnboardingSceneView {
    
    var sceneComplete: Binding<Bool>
    
    private let minimumTemplates: Int = 3
    
    @ObservedObject private var viewModel: OnboardingViewModel = OnboardingViewModel.shared
    
    private var templateCountString: String {
        "\(viewModel.selectedTemplateGoals.count) / \(minimumTemplates)"
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
            
            UniversalText(OnboardingSceneUIText.goalSceneInstructionText1,
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
        
        HStack {
            UniversalText(templateGoal.title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
        }
        
        .rectangularBackground(style: templateIsSelected ? .accent : .secondary)
            .onTapGesture { withAnimation {
                viewModel.toggleTemplateGoal(templateGoal)
                
                if viewModel.selectedTemplateGoals.count >= minimumTemplates {
                    sceneComplete.wrappedValue = true
                }
            } }
    }

//    MARK: makeTemplateGoalSelectors
    @ViewBuilder
    private func makeTemplateGoalSelectors() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            WrappedHStack(collection: templateGoals) { templateGoal in
                makeTemplateGoalSelector(templateGoal)
            }
            
        }
    }
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading) {
            makeHeader()
            
            makeTemplateGoalSelectors()
            
            Spacer()
        }
        .padding(7)
    }
}


#Preview {
    OnboardingGoalScene(sceneComplete: .constant(true))
}
