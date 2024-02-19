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

//    This determines whether its showing all time or just this week
    @State var viewFilter: Int = 0
    
    @EnvironmentObject var data: RecallDataModel
    
    @Binding var page: MainView.MainPage
    @Binding var currentDay: Date
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
//            DataCollection("Events") {
//                
//                let timePeriod: Double = viewFilter == 0 ? 7 : RecallModel.getDaysSinceFirstEvent()
//                
//                Group {
//                    LargeText(mainText: "\(data.getTotalHours(from: viewFilter).round(to: 2) )", subText: "hours")
//                    Seperator(orientation: .horizontal)
//                    LargeText(mainText: "\(data.getHourlData(from: viewFilter).count)", subText: "events")
//                    Seperator(orientation: .horizontal)
//                        .padding(.bottom)
//                }
//                
//                DataPicker(optionsCount: 2, labels: ["This Week", "All Time"], fontSize: Constants.UISubHeaderTextSize, selectedOption: $viewFilter)
//                    .padding(.bottom)
//
//                Group {
//                    UniversalText("Daily Averages", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
//                        .padding(.bottom, 5)
//
//                    AverageActivityByTag(recents: viewFilter == 0, data: data.getHourlData(from: viewFilter), unit: "")
//                    EventsDataSummaries.DailyAverage(data: data.getCompressedHourlData(from: viewFilter), unit: "HR/DY")
//
//                    LargeText(mainText: "\((Double(data.getTotalHours(from: viewFilter)) / timePeriod).round(to: 2))", subText: "HR/DY")
//                        .padding(.vertical)
//                }
//
//                Seperator(orientation: .horizontal)
//                
//                Group {
//                    UniversalText("Activities", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
//
//                    ActivitiesPerDay("Hours per day, by tag",
//                                     data: data.getHourlData(from: viewFilter),
//                                     scrollable: viewFilter == 1,
//                                     page: $page,
//                                     currentDay: $currentDay)
//                    EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedHourlData(from: viewFilter), unit: "HR")
//                    EventsDataSummaries.ActivityPerTag(data:        data.getCompressedHourlData(from: viewFilter), unit: "HR")
//
//                    Seperator(orientation: .horizontal)
//
//                    ActivitiesPerDay("Events per day, by tag",
//                                     data: data.getTagData(from: viewFilter),
//                                     scrollable: viewFilter == 1,
//                                     page: $page,
//                                     currentDay: $currentDay )
//                    EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedTagData(from: viewFilter), unit: "")
//                    EventsDataSummaries.ActivityPerTag(data:        data.getCompressedTagData(from: viewFilter), unit: "")
//
////                    Seperator(orientation: .horizontal)
//                }
//            }
        }.id( DataPageView.DataPage.Events.rawValue )
    }
    
}
