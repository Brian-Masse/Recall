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
    
    @ObservedResults( RecallGoal.self ) var goals
    
    @State var label: String = ""
    @State var goalRatings: Dictionary<String, String> = Dictionary()
    @State var color: Color = Colors.tint
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Form {
                Section( "Basic Info" ) {
                    
                    TextField("Label", text: $label)
                }
                
                Section( "Productivity" ) {
                    GoalRatingsView(goalRatings: $goalRatings, goals: Array( goals ))
                }
            }
            
            RoundedButton(label: "Create Label", icon: "lanyardcard") {
                let category = RecallCategory(ownerID: RecallModel.ownerID,
                                              label: label,
                                              goalRatings: goalRatings,
                                              color: color
                )
                RealmManager.addObject(category)
            }
        }
        
        Spacer()
    }
    
}
