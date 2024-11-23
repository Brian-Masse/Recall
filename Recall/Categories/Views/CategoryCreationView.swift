//
//  CategoryCreationView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

@MainActor
struct CategoryCreationView: View {
    
    @ViewBuilder
    private func makeTextField(title: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            UniversalText(title,
                          size: Constants.UIHeaderTextSize,
                          font: Constants.titleFont)
            
            TextField("", text: binding)
                .rectangularBackground(style: .secondary)
                .universalTextField()
        }
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedResults( RecallGoal.self,
                      where: { goal in goal.ownerID == RecallModel.ownerID }) var goals
    
    let editing: Bool
    let tag: RecallCategory?
    
    @State var label: String
    @State var goalRatings: Dictionary<String, String>
    @State var color: Color = Colors.defaultLightAccent
    
    @State var showingAlert: Bool = false
    
//    MARK: Submit
    private func submit() {
        
        if !checkCompletion() {
            showingAlert = true
            return
        }
        
        if !editing {
            let category = RecallCategory(ownerID: RecallModel.ownerID,
                                          label: label,
                                          goalRatings: goalRatings,
                                          color: color
            )
            RealmManager.addObject(category)
        }else {
            Task {
                await tag!.update(label: label,
                            goalRatings: goalRatings,
                            color: color)
            }
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    static func makeCateogryCreationView(editing: Bool, tag: RecallCategory? = nil) -> some View {
        if editing {
            CategoryCreationView(editing: true, tag: tag!, label: tag!.label, goalRatings: RecallCalendarEvent.translateGoalRatingList(tag!.goalRatings))
        } else {
            CategoryCreationView(editing: false, tag: nil, label: "", goalRatings: [:])
        }
    }
    
    private func checkCompletion() -> Bool {
        !self.label.isEmpty
    }
    
    private func hasGoalRating(at key: String) -> Bool {
        goalRatings[key] != nil && goalRatings[key] != "" && goalRatings[key] != "0"
    }
    
//    MARK: SectionBuilders
    
    @ViewBuilder
    private func makeOverviewSection() -> some View {
        StyledTextField(title: "What would you like to call this tag?", binding: $label)
            .padding(.bottom)
        
        StyledColorPicker(label: "What Color is this tag?", color: $color)
        .padding(.bottom)
    }
    
    @ViewBuilder
    private func makeGoalSelection() -> some View {
        VStack(alignment: .leading) {
            UniversalText( "What goals should this tag contribute to?", size: Constants.formQuestionTitleSize, font: Constants.titleFont )
            WrappedHStack(collection: Array(goals)) { goal in
                let key = goal.getEncryptionKey()
                
                HStack {
                    RecallIcon("arrow.up.forward")
                    UniversalText(goal.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                }
                .if(!hasGoalRating(at: key)) { view in view.rectangularBackground(style: .secondary) }
                .if(hasGoalRating(at: key)) { view in view.rectangularBackground(style: .accent, foregroundColor: .black) }
                .onTapGesture {
                    if goalRatings[key] == nil { goalRatings[key] = "1" }
                    else { goalRatings[key] = nil }
                }
            }.padding(.bottom)
            
            if goalRatings.count != 0 {
                VStack(alignment: .leading) {
                    UniversalText( "How much should this tag contribute to those goals?", size: Constants.formQuestionTitleSize, font: Constants.titleFont )
                    ForEach(goals, id: \.key) { goal in
                        if Int(goalRatings[goal.key] ?? "0") ?? 0 != 0 {
                            GoalMultiplierSelector(goal: goal, goalRatings: $goalRatings, showToggle: false)
                        }
                    }
                }
            }
        }
    }
    
    private enum TagCreationFormSection : Int, CreationFormEnumProtocol {
        case overview
        case goals
    }
    
//    MARK: Body
    var body: some View {
        
        let title = editing ? "Edit Tag" : "Create Tag"
        
        CreationFormView(title, section: TagCreationFormSection.self, submit: submit) { section in
            switch section {
            case .overview : makeOverviewSection()
            case .goals : makeGoalSelection()
            }
        }
        .defaultAlert($showingAlert,
                      title: "Incomplete Form",
                      description: "Please provide a label before creating the tag")
    }
}
