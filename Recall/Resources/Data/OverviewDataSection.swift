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
        
        VStack(alignment: .leading) {
            
            DataCollection("Overview") {
                
                UniversalText("Events", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                ActivitiesPerDay("Hours per day, by tag",
                                 data: data.getHourlData(from: 1),
                                 scrollable: true,
                                 page: $page,
                                 currentDay: $currentDay
                )
                EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedHourlData(from: 1), unit: "HR")
                    .padding(.bottom)
                
                UniversalText("Goals", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                GoalAverages(title: "Times Met", data: data.metData, unit: "")
                    .padding(.bottom)
                GoalCompletionOverTime(data: data.goalsMetOverTimeData, unit: "")
                    .frame(height: 200)
//
                
            }
        }.id( DataPageView.DataBookMark.Overview.rawValue )
    }
}

