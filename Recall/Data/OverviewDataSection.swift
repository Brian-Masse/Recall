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
    @Binding var page: MainView.MainPage

    
//    MARK: Body
    var body: some View {
        
        DataCollection { data.overviewDataLoaded } makeData: { 
            await data.makeOverviewData()
        } content: {

            ActivitiesPerDay("Daily Recalls",
                             data: data.getHourlData(from: .allTime),
                             scrollable: true,
                             page: $page,
                             currentDay: $currentDay
            )
            EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedHourlData(from: .allTime), unit: "HR")
            
            GoalAverages(title: "Goal Completions", data: data.metData, unit: "")
            GoalCompletionOverTime(data: data.goalsMetOverTimeData, unit: "")
                .frame(height: 250)
        }
    }
}

