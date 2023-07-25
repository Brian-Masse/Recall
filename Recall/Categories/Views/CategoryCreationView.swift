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
    
    private func submit() {
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
    
    private func hasGoalRating(at key: String) -> Bool {
        goalRatings[key] != nil && goalRatings[key] != "" && goalRatings[key] != "0"
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            UniversalText(editing ? "Edit Tag" : "Create Tag", size: Constants.UITitleTextSize, font: Constants.titleFont)
                .foregroundColor(.black)
                .padding(.bottom)
            
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
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
                    
                    UniversalText( "What goals should this tag contribute to?", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(goals) { goal in
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
                                
                            }
                        }.padding(5)
                    }
                    .padding(.bottom)
                }
                
                Spacer()
                
                LargeRoundedButton("Done", icon: "arrow.down") { submit() }
                
            }
            .padding(5)
            .universalTextStyle()
            .opaqueRectangularBackground()
        }
        .padding(Constants.UIFormPagePadding)
        .background(Colors.tint)
    }
}
