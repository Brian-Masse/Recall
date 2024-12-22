//
//  GoalsDataSection.swift
//  Recall
//
//  Created by Brian Masse on 8/3/23.
//

import Foundation
import SwiftUI
import UIUniversals

struct GoalsDataSection: View {
    
    let goals: [RecallGoal]
    @EnvironmentObject var data: RecallDataModel

    
//    MARK: Body
    var body: some View {
        
        DataCollection(dataLoaded: $data.goalsDataLoaded) { await data.makeGoalsData() } content: {

            Group {
                GoalsMetPercentageChart(title: "Goals Completion Rates", data: data.metPercentageData, unit: "%")
                GoalsDataSummaries.GoalsMetPercentageBreakdown(data: data.metPercentageData)
                
                LargeText(mainText: "\(Int(data.totalGoalsMet))", subText: "Goals met  ")
                    .frame(height: 60)
                LargeText(mainText: "\(data.totalGoalsMetPercentage.round(to: 1))", subText: "%")
                    .frame(height: 60)
                
                GoalAverages(title: "Goal Completions", data: data.metData, unit: "")
                GoalsDataSummaries.GoalsMetCount(data: data.metData.filter { node in node.category == "completed" } )
                    .padding(.bottom, 7)
            }
            
            Divider(strokeWidth: 1)
            
            Group {
                GoalCompletionOverTime(data: data.goalsMetOverTimeData, unit: "")
                    .frame(height: 250)
                
                GoalProgressOverTime(title: "Goal progress over time", data: data.progressOverTime, unit: "%")
                    .frame(height: 260)
                    .padding(.bottom)
            } 
        }
    }
}
