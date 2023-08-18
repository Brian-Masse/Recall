//
//  RecallGoalDataModel.swift
//  Recall
//
//  Created by Brian Masse on 8/17/23.
//

import Foundation
import SwiftUI

class RecallGoalDataModel: ObservableObject {
    
    @Published var progressData: Double = 0 
    @Published var averageData: Double = 0
    @Published var goalMetData: (Int, Int) = (0, 0)
    
    var roundedProgressData: Double {
        progressData.round(to: 2)
    }
    
    @MainActor
    func makeData(for goal: RecallGoal, with events: [RecallCalendarEvent]) async {
        
        progressData = await goal.getProgressTowardsGoal(from: events)
        averageData = await goal.getAverage(from: events)
        goalMetData = await goal.countGoalMet(from: events)
        
    }
}
