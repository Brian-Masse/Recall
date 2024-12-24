//
//  OnboardingViewModel.swift
//  Recall
//
//  Created by Brian Masse on 12/28/24.
//

import Foundation
import SwiftUI

class OnboardingViewModel: ObservableObject {
    
    static let shared = OnboardingViewModel()
    
    @MainActor
    func onSubmit(_ scene: OnBoardingScene) {
        switch scene {
        case .goalTutorial:
            goalSceneSubmitted(self.selectedTemplateGoals)
        default: return
        }
    }
    
//    MARK: - OnboardingGoalScene
    @Published var selectedTemplateGoals: [TemplateGoal] = []
    
    func toggleTemplateGoal(_ templateGoal: TemplateGoal) {
        if let index = selectedTemplateGoals.firstIndex(of: templateGoal) {
            self.selectedTemplateGoals.remove(at: index)
        } else {
            self.selectedTemplateGoals.append(templateGoal)
        }
    }
    
    
//    MARK: goalSceneSubmitted
//    translates a list of selected templates into real RecallGoal objects that the user owns
    @MainActor
    func goalSceneSubmitted( _ selectedTemplates: [TemplateGoal] ) {    
        if inDev { return }
        
        for templateGoal in selectedTemplates {
            let goal = RecallGoal(ownerID: RecallModel.ownerID,
                                  label: templateGoal.title,
                                  description: "",
                                  frequency: templateGoal.frequency,
                                  targetHours: Int(templateGoal.targetHours),
                                  priority: RecallGoal.Priority(rawValue: templateGoal.priority) ?? .low,
                                  type: .hourly,
                                  targetTag: nil)
            
            RealmManager.addObject(goal)
        }
    }
}
