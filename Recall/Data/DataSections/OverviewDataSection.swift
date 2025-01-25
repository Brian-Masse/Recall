//
//  OverviewDataSection.swift
//  Recall
//
//  Created by Brian Masse on 8/16/23.
//

import Foundation
import SwiftUI
import UIUniversals

struct OverviewDataSection: View {
    
    let goals: [RecallGoal]
    @EnvironmentObject var data: RecallDataModel
    
    @Binding var currentDay: Date
    
//    MARK: Body
    var body: some View {
        
        DataCollection(dataLoaded: $data.overviewDataLoaded) { await data.makeOverviewData() } content: {

            if data.getHourlData(from: .allTime).count > 10 {
                ActivitiesPerDay("Daily Recalls",
                                 data: data.getHourlData(from: .allTime),
                                 scrollable: true,
                                 currentDay: $currentDay
                )
                EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedHourlData(from: .allTime), unit: "HR")
            } else {
                makeSectionFiller(icon: "chart.xyaxis.line", message: "Continuing Uisng Recall to view your data and trends") { }
            }
            
//            GoalAverages(title: "Goal Completions", data: data.metData, unit: "")
//            GoalCompletionOverTime(data: data.goalsMetOverTimeData, unit: "")
//                .frame(height: 250)
        }
    }
}

