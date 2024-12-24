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
private struct TemplateGoal: Equatable, Identifiable {
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
struct OnboardingGoalScene: View {
    
    @State private var selectedTemplateGoals: [TemplateGoal] = []
    
    private func toggleTemplateGoal(_ templateGoal: TemplateGoal) {
        if let index = selectedTemplateGoals.firstIndex(of: templateGoal) {
            self.selectedTemplateGoals.remove(at: index)
        } else {
            self.selectedTemplateGoals.append(templateGoal)
        }
    }
    
//    MARK: makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        VStack(alignment: .leading) {
            HStack {
                UniversalText("Goals", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                
                Spacer()
            }
            
            UniversalText(OnboardingSceneUIText.goalSceneInstructionText1,
                          size: Constants.UIDefaultTextSize,
                          font: Constants.mainFont)
            .opacity(0.75)
        }
    }
    
//    MARK: makeTemplateGoalSelector
    private func templateIsSelected(_ template: TemplateGoal) -> Bool {
        selectedTemplateGoals.firstIndex(of: template) != nil
    }
    
    @ViewBuilder
    private func makeTemplateGoalSelector(_ templateGoal: TemplateGoal) -> some View {
        
        UniversalText(templateGoal.title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
        
            .rectangularBackground(style: templateIsSelected(templateGoal) ? .accent : .secondary)
            .onTapGesture { withAnimation {
                toggleTemplateGoal(templateGoal)
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
    OnboardingGoalScene()
}
