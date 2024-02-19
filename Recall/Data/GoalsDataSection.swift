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
        
        VStack(alignment: .leading) {
            
//            DataCollection("Goals") {
//                
//                LargeText(mainText: "\(goals.count)", subText: "goals")
//                Seperator(orientation: .horizontal)
//                    .padding(.bottom)
//                
//                Group {
//                    UniversalText("Goal Meeting Rates", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
//                    
//                    GoalAverages(title: "Times Met", data: data.metData, unit: "")
//                        .padding(.bottom)
//                    
//                    GoalsDataSummaries.GoalsMetCount(data: data.metData.filter { node in node.category == "completed" } )
//                    
//                    GoalsMetPercentageChart(title: "Goals Met Percentage", data: data.metPercentageData, unit: "%")
//                    
//                    GoalsDataSummaries.GoalsMetPercentageBreakdown(data: data.metPercentageData)
//                        .padding(.bottom)
//                    
//                    Seperator(orientation: .horizontal)
//                    LargeText(mainText: "\(Int(data.totalGoalsMet))", subText: "Goals met")
//                    Seperator(orientation: .horizontal)
//                    LargeText(mainText: "\(data.totalGoalsMetPercentage.round(to: 1))", subText: "% met")
//                    Seperator(orientation: .horizontal)
//                        .padding(.bottom)
//
//                }
//                
//                Group {
//                    UniversalText("Goals Over Time", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
//                    
//                    GoalCompletionOverTime(data: data.goalsMetOverTimeData, unit: "")
//                        .frame(height: 200)
//                        .padding(.bottom)
//                    
//                    GoalProgressOverTime(title: "Goal progress over time", data: data.progressOverTime, unit: "%")
//                        .frame(height: 200)
//                        .padding(.bottom)
//                    
//                    GoalProgressOverTime(title: "Goals met over time", data: data.metOverTime, unit: "")
//                        .frame(height: 200)
//                        .padding(.bottom)
//                }   
//            }
        }.id( DataPageView.DataPage.Goals.rawValue )
    }
}
