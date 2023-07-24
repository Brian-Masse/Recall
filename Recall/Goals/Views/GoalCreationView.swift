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
    
    @ViewBuilder
    private func makeTextField(title: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            UniversalText(title, size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
            
            TextField("", text: binding)
                .secondaryOpaqueRectangularBackground()
                .universalTextField()
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
    
    private var hoursBinding: Binding<String> {
        Binding { "\(Int(targetHours))"
        } set: { newValue, _ in targetHours = Float(newValue) ?? 0 }
    }
    
    @MainActor
    private func submit() {
        if !editing {
            let goal = RecallGoal(ownerID: RecallModel.ownerID,
                                  label: label,
                                  description: description,
                                  frequency: frequence.numericValue,
                                  targetHours: Int(targetHours),
                                  priority: priority)
            RealmManager.addObject(goal)
        } else {
            goal!.update(label: label,
                        description: description,
                        frequency: frequence,
                         targetHours: Int(targetHours),
                         priority: priority
            )
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    let editing: Bool
    let goal: RecallGoal?
    
    @State var label: String
    @State var description: String
    @State var frequence: RecallGoal.GoalFrequence
    @State var targetHours: Float
    @State var priority: RecallGoal.Priority
    
    var body: some View {
        
        VStack(alignment: .leading) {
            UniversalText(editing ? "Edit Goal" : "Create Goal", size: Constants.UITitleTextSize, font: Constants.titleFont, true)
                .padding(.bottom)
                .foregroundColor(.black)
            
            ScrollView(.vertical) {
                VStack {
                    makeTextField(title: "What's the name of this goal?", binding: $label)
                    makeTextField(title: "What's the purpose of this goal?", binding: $description)
                        .padding(.bottom)
                    
                    UniversalText("How frequently do you want to meet this goal?", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
                    
                    HStack {
                        makePickerOptions(label: "Daily", selection: .daily)
                        makePickerOptions(label: "Weekly", selection: .weekly)
                    }
                    
                    UniversalText("How many hours do you want to spend on this goal?", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
                    
                    HStack {
                        Slider(value: $targetHours, in: 0...(frequence == .daily ? 12 : 50 ))
                            .tint(Colors.tint)
                        
                        TextField("", text: hoursBinding)
                            
                            .universalTextField()
                            .frame(width: 60)
                        
                    }.padding(.bottom)
                    
                    UniversalText("How would you like to prioritize this goal?", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
                    
                    HStack {
                        makePriorityPickerOptions(label: "High", selection: .high)
                        makePriorityPickerOptions(label: "Medium", selection: .medium)
                        makePriorityPickerOptions(label: "Low", selection: .low)
                    }
                    
                    LargeRoundedButton("Done", icon: "arrow.down") { submit() }
                    
                }
                .padding(5)
                .universalTextStyle()
                .opaqueRectangularBackground()
            }
        }
        .padding(5)
        .background(Colors.tint)
        .universalBackground()
    }
    
}
