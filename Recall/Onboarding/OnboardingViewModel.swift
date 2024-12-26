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
    
//    MARK: onSubmit
    @MainActor
    func onSubmit(_ scene: OnBoardingScene) {
        switch scene {
        case .goalTutorial:
            goalSceneSubmitted(self.selectedTemplateGoals)
        case .tagsTutorial:
            Task { await tagSceneSubmitted(self.selectedTemplateTags) }
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

//    MARK: - OnboardingTagScene
    @Published var selectedTemplateTags: [TemplateTag] = []
    
    func toggleTemplateTag(_ templateTag: TemplateTag) {
        if let index = selectedTemplateTags.firstIndex(of: templateTag) {
            self.selectedTemplateTags.remove(at: index)
        } else {
            self.selectedTemplateTags.append(templateTag)
        }
    }
    
    
//    MARK: goalSceneSubmitted
//    translates a list of selected templates into real RecallGoal objects that the user owns
    private func getGoalRatings(for tag: TemplateTag) async -> Dictionary<String, String> {
        let goalNames = selectedTemplateGoals.compactMap { goal in
            if tag.templateMask.contains(goal.tagMask) { return goal.title }
            return nil
        }
        
        let goals: [RecallGoal] = await RealmManager.retrieveObjectsInList()
            .filter { goal in goalNames.contains(goal.label) }
        
        return goals.reduce(into: [String: String]()) { partialResult, goal in
            partialResult[goal.key] = "1"
        }
    }
    
    @MainActor
    func tagSceneSubmitted( _ selectedTags: [TemplateTag] ) async {
        if inDev { return }

        for tagTemplate in selectedTags {
            
            let goalRatings = await getGoalRatings(for: tagTemplate)
            
            let tag = RecallCategory(ownerID: RecallModel.ownerID,
                                     label: tagTemplate.title,
                                     goalRatings: goalRatings,
                                     color: tagTemplate.color)   
        }
    }
}
