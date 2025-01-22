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
    
    case overview
    case howItWorks
    
    case authentication
    case profileSetup1
    case profileSetup2
    
    case goalTutorial
    case tagsTutorial
    case eventsTutorial
    case calendarTutorial1
    case calendarTutorial2
    
    case complete
    
//    case overview
//    case howItWorks
    
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
        case async
    }
    
    static let shared = OnboardingViewModel()
    
    private(set) var inOnboarding: Bool = false
    
    @Published private(set) var scene: OnBoardingScene = .calendarTutorial2
    @Published private(set) var sceneStatus: SceneStatus = .incomplete
    
    @Published var triggerBackgroundUpdate: Bool = false
    
    var sceneComplete: Bool { sceneStatus == .complete }
    
    @Published var currentSceneProgress: Double = 0
    
    func setSceneStatus(to status: SceneStatus) {
        withAnimation { sceneStatus = status }
    }
    
    //    MARK: IncrementScene
    @MainActor
    func incrementScene() {
        withAnimation {
            self.scene = scene.incrementScene()
            self.setSceneStatus(to: .incomplete)
            self.currentSceneProgress =  Double(scene.rawValue) / Double(OnBoardingScene.allCases.count)
        }
        
        if self.scene == .complete { submit() }
    }
    
    func setOnboardingStatus(to status: Bool) {
        self.inOnboarding = status
    }
    
    @MainActor
    private func submit() {
        inOnboarding = false
        RecallModel.index.finishTutorial()
        RecallModel.realmManager.setState(.complete)
    }
    
    //    MARK: - OnboardingGoalScene
    @Published var selectedTemplateGoals: [TemplateGoal] = []
    
    let minimumGoalTemplates: Int = 3
    
//    if the user already has 3+ goals, allow them to continue
    @MainActor
    func checkInitialGoals() {
        if inDev { return }
        
        let goals: [RecallGoal] = RealmManager.retrieveObjectsInList()
        if goals.count >= minimumGoalTemplates {
            self.setSceneStatus(to: .complete)
        }
    }
    
    func toggleTemplateGoal(_ templateGoal: TemplateGoal) {
        if let index = selectedTemplateGoals.firstIndex(of: templateGoal) {
            self.selectedTemplateGoals.remove(at: index)
        } else {
            self.selectedTemplateGoals.append(templateGoal)
        }
        
        if selectedTemplateGoals.count >= minimumGoalTemplates {
            self.setSceneStatus(to: .complete)
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
    
    let minimumTagTemplates: Int = 3
    
//    if the user already has 3+ goals, allow them to continue
    @MainActor
    func checkInitialTags() {
        if inDev { return }
        
        let tags: [RecallCategory] = RealmManager.retrieveObjectsInList()
        if tags.count >= minimumTagTemplates {
            self.setSceneStatus(to: .complete)
        }
    }
    
    func toggleTemplateTag(_ templateTag: TemplateTag) {
        if let index = selectedTemplateTags.firstIndex(of: templateTag) {
            self.selectedTemplateTags.remove(at: index)
        } else {
            self.selectedTemplateTags.append(templateTag)
        }
        
        if selectedTemplateTags.count >= minimumTagTemplates {
            self.setSceneStatus(to: .complete)
        }
    }
    
    
    //    MARK: goalSceneSubmitted
    //    translates a list of selected templates into real RecallGoal objects that the user owns
    @MainActor
    private func getGoalRatings(for tag: TemplateTag) async -> Dictionary<String, String> {
        let goalNames = selectedTemplateGoals.compactMap { goal in
            if tag.templateMask.contains(goal.tagMask) { return goal.title }
            return nil
        }
        
        let goals: [RecallGoal] = RealmManager.retrieveObjectsInList()
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
            
            RealmManager.addObject(tag)
        }
    }
    
    //    MARK: - OnboardingEventScene
    @Published var recentRecalledEventCount: Int = 0
    
    @MainActor
    func getRecalledEventCount(from events: [RecallCalendarEvent]) async {
        let results = events.filter { $0.startTime > Date.now - Constants.DayTime * 7 }
        self.recentRecalledEventCount = results.count
    }
    
//    MARK: - AuthenticationScene
    
    func submitProfileDemographics( firstName: String, lastName: String, birthday: Date ) {
        if inDev { return }
        
        RecallModel.index.update(firstName: firstName,
                                 lastName: lastName,
                                 email: RecallModel.realmManager.email,
                                 phoneNumber: 0,
                                 dateOfBirth: birthday)
    }
}



//MARK: - onBoardingSceneUIText
struct OnboardingSceneUIText {
    
//    profile
    static let profileSceneIntroductionText =
        "Your profile privately holds your data and allows you to customize Recall"
    
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
    
    static let calendarSceneIntroductionText =
        "The calendar lets you browse, create, and edit all your events"
    static let calendarSceneInstructionText =
        "Recall a couple of events from your day today to get familiar with the app"
}
