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
    
    @Binding var page: MainView.MainPage
    @Binding var currentDay: Date
    
    @State var timePeriod: RecallDataModel.TimePeriod = .allTime
    
    @State var dataPrepared: Bool = true
    
    private var daysInTimePeriod: Double {
        timePeriod == .recent ? 7 : RecallModel.getDaysSinceFirstEvent()
    }
    
//    MARK: ViewBuilder
    @ViewBuilder
    private func makeTimePeriodSelector( _ period: RecallDataModel.TimePeriod, label: String, icon: String ) -> some View {
        
        HStack {
            Spacer()
            UniversalText(label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            Image(systemName: icon)
            Spacer()
        }
        .if( period != timePeriod) { view in view.rectangularBackground(style: .secondary) }
        .if( period == timePeriod ) { view in
            view
                .foregroundStyle(.black)
                .rectangularBackground(style: .accent)
        }
        .onTapGesture { withAnimation {
            self.dataPrepared = false
            self.timePeriod = period
            
            Task {
                await RecallModel.wait(for: 0.5)
                withAnimation { self.dataPrepared = true }
            }
        } }
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
                LargeText(mainText: "\((Double(data.getTotalHours(from: timePeriod)) / daysInTimePeriod).round(to: 2))",
                          subText: "HR/DY")
                
                AverageActivityByTag(recents: timePeriod == .recent,
                                     data: data.getCompressedHourlData(from: timePeriod),
                                     unit: "")
                
                EventsDataSummaries.DailyAverage(data: data.getCompressedHourlData(from: timePeriod), unit: "HR/DY")
            }
            
            Divider(strokeWidth: 1)
            
            Group {
                LargeText(mainText: "\(data.getTotalHours(from: timePeriod).round(to: 2) )", subText: "hours")
                LargeText(mainText: "\(data.getHourlData(from: timePeriod).count)", subText: "events")
            }
            
            Divider(strokeWidth: 1)
            
            Group {
                ActivitiesPerDay("Daily Recalls",
                                 data: data.getHourlData(from: timePeriod),
                                 scrollable: timePeriod == .allTime,
                                 page: $page,
                                 currentDay: $currentDay)
                EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedHourlData(from: timePeriod), unit: "HR")
                EventsDataSummaries.ActivityPerTag(data:        data.getCompressedHourlData(from: timePeriod), unit: "HR")

                ActivitiesPerDay("Daily Recalls, by tag",
                                 data: data.`getTagData`(from: timePeriod),
                                 scrollable: timePeriod == .allTime,
                                 page: $page,
                                 currentDay: $currentDay )
                EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedTagData(from: timePeriod), unit: "")
                EventsDataSummaries.ActivityPerTag(data:        data.getCompressedTagData(from: timePeriod), unit: "")

            }
        }
    }
}
