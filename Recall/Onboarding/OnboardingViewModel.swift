//
//  OnboardingViewModel.swift
//  Recall
//
//  Created by Brian Masse on 12/28/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - OnBoardingScene
//TODO: make goal + tag limits more apparent
enum OnBoardingScene: Int, CaseIterable {
    
    case authentication
    
    case goalTutorial
    case tagsTutorial
    case eventsTutorial
    case calendarTutorial
    
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

//MARK: - OnboardingViewModel
class OnboardingViewModel: ObservableObject {
    
    enum SceneStatus {
        case incomplete
        case complete
        case hideButton
    }
    
    static let shared = OnboardingViewModel()
    
    @Published private(set) var scene: OnBoardingScene = .authentication
    @Published private(set) var sceneStatus: SceneStatus = .incomplete
    
    var sceneComplete: Bool { sceneStatus == .complete }
    
    func setSceneStatus(to status: SceneStatus) {
        withAnimation { sceneStatus = status }
    }
    
//    MARK: IncrementScene
    @MainActor
    func incrementScene() {
        if sceneStatus != .complete { return }
        withAnimation {
            self.scene = scene.incrementScene()
            self.setSceneStatus(to: .incomplete)
        }
        onSubmit()
    }
    
//    MARK: onSubmit
    @MainActor
    private func onSubmit() {
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
    private func goalSceneSubmitted( _ selectedTemplates: [TemplateGoal] ) {
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
    private func tagSceneSubmitted( _ selectedTags: [TemplateTag] ) async {
        if inDev { return }

        for tagTemplate in selectedTags {
            
            let goalRatings = await getGoalRatings(for: tagTemplate)
            
            let tag = RecallCategory(ownerID: RecallModel.ownerID,
                                     label: tagTemplate.title,
                                     goalRatings: goalRatings,
                                     color: tagTemplate.color)   
        }
    }
    
//    MARK: - OnboardingEventScene
    @Published var recentRecalledEventCount: Int = 0
    
    @MainActor
    func getRecalledEventCount(from events: [RecallCalendarEvent]) async {
        let results = events.filter { $0.startTime > Date.now - Constants.DayTime * 7 }
        self.recentRecalledEventCount = results.count
    }
}



//MARK: - onBoardingSceneUIText
struct OnboardingSceneUIText {
    //goals
    static let goalSceneIntroductionText = 
        "Goals represent achievements you want to work towards each week."
    static let goalSceneInstructionText = 
        "Pick out some goals you want to work towards. You can always add, remove, or modify goals later "
    
    //tags
    static let tagSceneIntroductionText = 
        "Tags categorize events on your calendar. Each is linked with one or more goals"
    static let tagSceneInstructionText = 
        "Pick out tags for events you frequently do. You can always add, remove, or modify tags later"
    
//    events
    static let eventsSceneIntroductionText = 
        "Events are the driver behind Recall."
    static let eventsSceneInstructionText = 
        "This is a sample event, it contains lots of ways to help you better log and recall your memories"
    
    static let eventsTapAndHoldGestureInstruction =
        "You can tap and hold the calendar to quickly create an event"
    static let eventsContextMenuGestureInstruction = 
        "You can long press on an event to see more options and take quick actions"
}
