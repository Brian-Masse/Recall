//
//  CategoryCreationView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct CategoryCreationView: View {
    
    @ViewBuilder
    private func makeTextField(title: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            UniversalText(title, size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
            
            TextField("", text: binding)
                .secondaryOpaqueRectangularBackground()
                .universalTextField()
        }
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedResults( RecallGoal.self ) var goals
    
    let editing: Bool
    let tag: RecallCategory?
    
    @State var label: String
    @State var goalRatings: Dictionary<String, String>
    @State var color: Color
    
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
            tag!.update(label: label,
                        goalRatings: goalRatings,
                        color: color)
        }
        
        presentationMode.wrappedValue.dismiss()
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
        makeTextField(title: "What would you like to call this tag?", binding: $label)
            .padding(.bottom)
        
        UniversalText( "What Color is this tag?", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
        ScrollView(.horizontal) {
            HStack {
                Spacer()
                ForEach(Colors.colorOptions.indices, id: \.self) { i in
                    ColorPickerOption(color: Colors.colorOptions[i], selectedColor: $color)
                }
                ColorPicker("", selection: $color)
                Spacer()
            }
        }
        .padding(.bottom)
    }
    
    @ViewBuilder
    private func makeGoalSelection() -> some View {
        VStack(alignment: .leading) {
            UniversalText( "What goals should this tag contribute to?", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            WrappedHStack(collection: Array(goals)) { goal in
                let key = goal.getEncryptionKey()
                
                HStack {
                    Image(systemName: "arrow.up.forward")
                    UniversalText(goal.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                }
                .if(!hasGoalRating(at: key)) { view in view.secondaryOpaqueRectangularBackground() }
                .if(hasGoalRating(at: key)) { view in view.tintRectangularBackground() }
                .onTapGesture {
                    if goalRatings[key] == nil { goalRatings[key] = "1" }
                    else { goalRatings[key] = nil }
                }
            }.padding(.bottom)
            
            if goalRatings.count != 0 {
                VStack(alignment: .leading) {
                    UniversalText( "How much should this tag contribute to those goals?", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                    ForEach(goals, id: \.key) { goal in
                        if Int(goalRatings[goal.key] ?? "0") ?? 0 != 0 {
                            GoalMultiplierSelector(goal: goal, goalRatings: $goalRatings, showToggle: false)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 100)
    }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            
            UniversalText(editing ? "Edit Tag" : "Create Tag", size: Constants.UITitleTextSize, font: Constants.titleFont)
                .foregroundColor(.black)
                .padding(.bottom)
            
            ZStack(alignment: .bottom) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        
                        makeOverviewSection()
                        
                        makeGoalSelection()
                        
                    }
                }
                
                LargeRoundedButton("Done", icon: "arrow.down") { submit() }
                
            }
            .scrollDismissesKeyboard(ScrollDismissesKeyboardMode.immediately)
            .padding(5)
            .universalTextStyle()
            .opaqueRectangularBackground()
        }
        .scrollDismissesKeyboard(ScrollDismissesKeyboardMode.immediately)
        .padding([.top, .horizontal], Constants.UIFormPagePadding)
        .background(Colors.tint)
        
        .defaultAlert($showingAlert,
                      title: "Incomplete Form",
                      description: "Please provide a label before creating the tag")
    }
}
