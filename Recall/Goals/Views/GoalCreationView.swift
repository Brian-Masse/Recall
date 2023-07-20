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
    
    @State var label: String = ""
    @State var frequence: RecallGoal.GoalFrequence = .daily
    @State var targetHours: Float = 0
    
    private func getFrequence(from frequence: RecallGoal.GoalFrequence) -> Int {
        switch frequence {
        case .daily: return 1
        case .weekly: return 7
        }
           
    }
    
    var body: some View {
        
        VStack {
            
            Form {
                Section( "Basic Info" ) {
                  
                    TextField("Label", text: $label)
                    
                    BasicPicker(title: "Time Period",
                                noSeletion: "",
                                sources: RecallGoal.GoalFrequence.allCases,
                                selection: $frequence) { goal in Text( goal.rawValue ) }
                    
                    HStack {
                        Slider(value: $targetHours, in: 0...12)
                        Text( "\(targetHours.rounded(.down))" )
                    }
                    
                }
            }
            
            Spacer()
            
            RoundedButton(label: "Add Goal", icon: "gauge.medium.badge.plus") {
                let goal = RecallGoal(ownerID: RecallModel.ownerID, label: label, frequency: getFrequence(from: frequence), targetHours: Int(targetHours))
                RealmManager.addObject(goal)
            }
            
        }
    }
    
}
