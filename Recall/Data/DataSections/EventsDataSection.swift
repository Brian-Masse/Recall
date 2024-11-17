//
//  EventsDataSection.swift
//  Recall
//
//  Created by Brian Masse on 8/2/23.
//

import Foundation
import SwiftUI
import Charts
import UIUniversals

struct EventsDataSection: View {

//    MARK: Vars
    @EnvironmentObject var data: RecallDataModel
    
    @Binding var currentDay: Date
    
    @State var timePeriod: RecallDataModel.TimePeriod = .allTime
    
    private var daysInTimePeriod: Double {
        timePeriod == .recent ? 7 : RecallModel.getDaysSinceFirstEvent()
    }
    
//    MARK: ViewBuilder
    @ViewBuilder
    private func makeTimePeriodSelector( _ period: RecallDataModel.TimePeriod, label: String, icon: String ) -> some View {
        
        HStack {
            Spacer()
            UniversalText(label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            RecallIcon(icon)
            Spacer()
        }
        .if( period != timePeriod) { view in view.rectangularBackground(style: .secondary) }
        .if( period == timePeriod ) { view in
            view
                .foregroundStyle(.black)
                .rectangularBackground(style: .accent)
        }
        .onTapGesture { withAnimation { self.timePeriod = period } }
    }
    
    @ViewBuilder
    private func makeTimePeriodSelector() -> some View {
        VStack(alignment: .leading) {
            UniversalText( "Time Period", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            
            HStack {
                makeTimePeriodSelector(.allTime, label: "All Time", icon: "calendar")
                makeTimePeriodSelector(.recent, label: "This week", icon: "calendar.day.timeline.left")
            }
        }
    }
    
    
//    MARK: Body
    var body: some View {
        
        DataCollection { data.eventsDataLoaded } makeData: { await data.makeEventsData() } content: {
            
            makeTimePeriodSelector()
                .padding(.bottom)
            
            Group {
                AverageActivityByTag(recents: timePeriod == .recent,
                                     data: data.getCompressedHourlData(from: timePeriod),
                                     unit: "")
                EventsDataSummaries.DailyAverage(data: data.getCompressedHourlData(from: timePeriod), unit: "HR/DY")
                
                LargeText(mainText: "\((Double(data.getTotalHours(from: timePeriod)) / daysInTimePeriod).round(to: 2))",
                          subText: "HR/DY")
                .padding(.bottom, 7)
                
                ActivitiesPerDay("Daily Recalls",
                                 data: data.getHourlData(from: timePeriod),
                                 scrollable: timePeriod == .allTime,
                                 currentDay: $currentDay)
                EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedHourlData(from: timePeriod), unit: "HR")
                EventsDataSummaries.ActivityPerTag(data:        data.getCompressedHourlData(from: timePeriod), unit: "HR")

            }

            Divider(strokeWidth: 1)
            
            Group {
                LargeText(mainText: "\(data.getTotalHours(from: timePeriod).round(to: 2) )", subText: "hours")
                    .frame(height: 60)
                LargeText(mainText: "\(data.getHourlData(from: timePeriod).count)", subText: "events")
                    .frame(height: 60)
            }

            Group {
                ActivitiesPerDay("Daily Recalls, by tag",
                                 data: data.`getTagData`(from: timePeriod),
                                 scrollable: timePeriod == .allTime,
                                 currentDay: $currentDay )
                EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedTagData(from: timePeriod), unit: "")
                EventsDataSummaries.ActivityPerTag(data:        data.getCompressedTagData(from: timePeriod), unit: "")

            }
        }
    }
}
