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
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Form {
                Section( "Basic Info" ) {
                    
                    TextField("Label", text: $label)
                }
                
                Section( "Productivity" ) {
                    GoalRatingsView(goalRatings: $goalRatings, goals: Array( goals ))
                }
                
                UniqueColorPicker(selectedColor: $color)
            }
            
            RoundedButton(label: "Create Label", icon: "lanyardcard") { submit() }
        }
        
        Spacer()
    }
    
}
