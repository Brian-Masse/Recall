//
//  GoalsDataSection.swift
//  Recall
//
//  Created by Brian Masse on 8/3/23.
//

import Foundation
import SwiftUI

struct GoalsDataSection: View {
    
    let goals: [RecallGoal]
    @EnvironmentObject var data: RecallDataModel
    
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            
            DataCollection("Goals") {
                
                Seperator(orientation: .horizontal)
                LargeText(mainText: "\(goals.count)", subText: "goals")
                Seperator(orientation: .horizontal)
                    .padding(.bottom)
                
                Group {
                    UniversalText("Goals Over Time", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                    
                    GoalCompletionOverTime(data: data.goalsMetOverTimeData, unit: "")
                        .frame(height: 200)
                        .padding(.bottom)
                    
                    GoalProgressOverTime(data: data.progressOverTime, unit: "%")
                        .frame(height: 200)
                        .padding(.bottom)
                    
                    GoalProgressOverTime(data: data.metOverTime, unit: "")
                        .frame(height: 200)
                        .padding(.bottom)
                }
                
                Seperator(orientation: .horizontal)
                    .padding(.bottom)
                    
                Group {
                    UniversalText("Counts", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                        .padding(.bottom)
                    
//                    GoalAverages(title: "Goal Progress", data: data.progressData, unit: "")
//                        .padding(.bottom)
                    
                    GoalAverages(title: "Times Met", data: data.metData, unit: "")
                        .padding(.bottom)
                    
                    GoalsDataSummaries.GoalsMetCount(data: data.metData)
                    
                    Seperator(orientation: .horizontal)
                    LargeText(mainText: "\(Int(data.totalGoalsMet))", subText: "Goals met")
                    Seperator(orientation: .horizontal)
                        .padding(.bottom)
                }
                
                Group {
                    GoalsMetPercentageChart(title: "Goals Met Percentage", data: data.metPercentageData, unit: "%")
                    
                    GoalsDataSummaries.GoalsMetPercentageBreakdown(data: data.metPercentageData)
                        .padding(.bottom)
                }
            }
        }.id( DataPageView.DataBookMark.Goals.rawValue )
    }
}
