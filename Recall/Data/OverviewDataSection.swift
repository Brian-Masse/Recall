//
//  OverviewDataSection.swift
//  Recall
//
//  Created by Brian Masse on 8/16/23.
//

import Foundation
import SwiftUI

struct OverviewDataSection: View {
    
    let goals: [RecallGoal]
    @EnvironmentObject var data: RecallDataModel

    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            
            DataCollection("Overview") {
                
                UniversalText("Events", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                ActivitiesPerDay("Hours per day, by tag", data: data.getHourlData(from: 1), scrollable: true )
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

