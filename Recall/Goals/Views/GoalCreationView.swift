//
//  GoalCreationView.swift
//  Recall
//
//  Created by Brian Masse on 7/19/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct GoalCreationView: View {
    
//    MARK: ViewBuilders
    @ViewBuilder
    static func makeGoalCreationView(editing: Bool, goal: RecallGoal? = nil) -> some View {
        if editing {
            GoalCreationView(editing: true,
                             goal: goal!,
                             label: goal!.label,
                             description: goal!.goalDescription,
                             frequence: RecallGoal.GoalFrequence.getRawType(from: goal!.frequency),
                             targetHours: Float(goal!.targetHours),
                             priority: RecallGoal.Priority.getRawType(from: goal!.priority),
                             type: RecallGoal.GoalType.getRawType(from: goal!.type),
                             targetTag: goal!.targetTag,
                             creationDate: goal!.creationDate)
        } else {
            GoalCreationView(editing: false,
                             goal: nil,
                             label: "",
                             description: "",
                             frequence: .weekly,
                             targetHours: 7,
                             priority: .medium,
                             type: .hourly,
                             targetTag: nil,
                             creationDate: .now)
        }
    }
    
    
//    TODO: These two should likley be one function, but for now I've seperated them into two for conveinience
    @ViewBuilder func makePickerOptions(label: String, selection: RecallGoal.GoalFrequence) -> some View {
        UniversalText(label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            .onTapGesture { frequence = selection }
            .if(frequence == selection) { view in
                view.accentRectangularBackground()
            }
            .if(frequence != selection) { view in
                view
                    .padding(10)
                    .secondaryOpaqueRectangularBackground()
            }
    }
    
    @ViewBuilder func makePriorityPickerOptions(label: String, selection: RecallGoal.Priority) -> some View {
        UniversalText(label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            .onTapGesture { priority = selection }
            .if(priority == selection) { view in
                view.accentRectangularBackground()
            }
            .if(priority != selection) { view in
                view
                    .padding(10)
                    .secondaryOpaqueRectangularBackground()
            }
    }
    
    @ViewBuilder func makeTypePickerOption(label: String, selection: RecallGoal.GoalType) -> some View {
        UniversalText(label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            .onTapGesture { type = selection }
            .if(type == selection) { view in view.accentRectangularBackground() }
            .if(type != selection) { view in
                view
                    .padding(10)
                    .secondaryOpaqueRectangularBackground()
            }
    }
    
    private var hoursBinding: Binding<String> {
        Binding { "\(Int(targetHours))"
        } set: { newValue, _ in targetHours = Float(newValue) ?? 0 }
    }
    
//    MARK: submit
    @MainActor
    private func submit() {
        if !checkCompletion() {
            showingAlert = true
            return
        }
        
        if !editing {
            let goal = RecallGoal(ownerID: RecallModel.ownerID,
                                  label: label,
                                  description: description,
                                  frequency: frequence.numericValue,
                                  targetHours: Int(targetHours),
                                  priority: priority,
                                  type: type,
                                  targetTag: targetTag)
            RealmManager.addObject(goal)
        } else {
            goal!.update(label: label,
                        description: description,
                        frequency: frequence,
                         targetHours: Int(targetHours),
                         priority: priority,
                         type: type,
                         targetTag: targetTag,
                         creationDate: creationDate)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func checkCompletion() -> Bool {
        !self.label.isEmpty && !self.description.isEmpty
    }
    
//    MARK: Vars
    @Environment(\.presentationMode) var presentationMode
    @ObservedResults(RecallCategory.self) var tags
    
    let editing: Bool
    let goal: RecallGoal?
    
    @State var label: String
    @State var description: String
    @State var frequence: RecallGoal.GoalFrequence
    @State var targetHours: Float
    @State var priority: RecallGoal.Priority
    @State var type: RecallGoal.GoalType
    @State var targetTag: RecallCategory?
    
    @State var creationDate: Date
    
    @State var showingAlert: Bool = false
    
//    MARK: sectionBuilders
    @ViewBuilder
    private func makeOverviewSection() -> some View {
        VStack(alignment: .leading) {
            TextFieldWithPrompt(title: "What's the name of this goal?", binding: $label)
            TextFieldWithPrompt(title: "What's the purpose of this goal?", binding: $description)
                .padding(.bottom)
        }
        
        UniversalText("How frequently do you want to meet this goal?", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
        HStack {
            Spacer()
            makePickerOptions(label: "Daily", selection: .daily)
            makePickerOptions(label: "Weekly", selection: .weekly)
            Spacer()
        } .padding(.bottom)
    }
    
    @ViewBuilder
    private func makeTagSelection() -> some View {
        UniversalText("What type of goal is this?", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
        HStack {
            Spacer()
            makeTypePickerOption(label: "hourly", selection: .hourly)
            makeTypePickerOption(label: "by tag", selection: .byTag)
            Spacer()
        }.padding(.bottom)
        
        if type == .byTag {
            Group {
                UniversalText("Which tag would you like to track?", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
                WrappedHStack(collection: Array(tags)) { tag in
                    HStack {
                        Image(systemName: "tag")
                        UniversalText(tag.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                    }
                    .onTapGesture { targetTag = tag }
                    .if( targetTag?.label ?? "" != tag.label ) { view in view.secondaryOpaqueRectangularBackground() }
                    .if( targetTag?.label ?? "" == tag.label ) { view in view.tintRectangularBackground() }
                }
            }.padding(.bottom)
        }
    }
    
    @ViewBuilder
    private func makeTargetSelector() -> some View {
        SliderWithPrompt(label: type == .byTag ? "How many tagged events would you like to complete this goal?" : "How many hours do you want to spend on this goal?",
                         minValue: 0,
                         maxValue: (frequence == .daily ? 12 : 50 ),
                         binding: $targetHours,
                         strBinding: hoursBinding,
                         textFieldWidth: Constants.UIFormSliderTextFieldWidth)
        .padding(.bottom)
    }
    
    @ViewBuilder
    private func makePrioritySelector() -> some View {
        UniversalText("How would you like to prioritize this goal?", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
        HStack {
            Spacer()
            makePriorityPickerOptions(label: "High", selection: .high)
            makePriorityPickerOptions(label: "Medium", selection: .medium)
            makePriorityPickerOptions(label: "Low", selection: .low)
            Spacer()
        }.padding(.bottom, 100)
    }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            UniversalText(editing ? "Edit Goal" : "Create Goal", size: Constants.UITitleTextSize, font: Constants.titleFont, true)
                .padding(.bottom)
                .foregroundColor(.black)

            ZStack(alignment: .bottom) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        
//                        DatePicker("temp", selection: $creationDate)
//                            .developer()
                        
                        makeOverviewSection()
                        
                        makeTagSelection()
                        
                        makeTargetSelector()
                        
                        makePrioritySelector()

                    }
                }
                
                LargeRoundedButton("Done", icon: "arrow.down") { submit() }
            }
            .padding(5)
            .universalTextStyle()
            .opaqueRectangularBackground()
        }
        .scrollDismissesKeyboard(ScrollDismissesKeyboardMode.immediately)
        .padding([.top, .horizontal], Constants.UIFormPagePadding)
        .background(Colors.tint)
        .ignoresSafeArea()
        .defaultAlert($showingAlert,
                      title: "Incomplete Form",
                      description: "Please provide a name, description, and target before creating the goal")
    }
    
}
