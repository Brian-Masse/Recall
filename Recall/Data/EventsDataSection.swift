//
//  EventsDataSection.swift
//  Recall
//
//  Created by Brian Masse on 8/2/23.
//

import Foundation
import SwiftUI
import Charts

struct EventsDataSection: View {

//    This determines whether its showing all time or just this week
    @State var viewFilter: Int = 0
    
    @EnvironmentObject var data: RecallDataModel
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            DataCollection("Events") {
                
                Group {
                    Seperator(orientation: .horizontal)
                    LargeText(mainText: "\(data.totalHours)", subText: "hours")
                    Seperator(orientation: .horizontal)
                    LargeText(mainText: "\(data.hourlyData.count)", subText: "events")
                    Seperator(orientation: .horizontal)
                }
                
                DataPicker(optionsCount: 2, labels: ["This Week", "All Time"], fontSize: Constants.UISubHeaderTextSize, selectedOption: $viewFilter)
                    .padding(.bottom)
                
                Group {
                    UniversalText("Daily Averages", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                        .padding(.bottom, 5)
                    
                    AverageActivityByTag(data: data.getHourlData(from: viewFilter), unit: "")
                    Seperator(orientation: .horizontal)
                    LargeText(mainText: "\((Double(data.totalHours) / Double(data.hourlyData.count)).round(to: 2))", subText: "HR/DY")
                        .padding(.vertical)
                    EventsDataSummaries.DailyAverage(data: data.getCompressedHourlData(from: viewFilter), unit: "HR/DY")
                }
                
                Seperator(orientation: .horizontal)
                
                Group {
                    UniversalText("Activities", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                    
                    ActivitiesPerDay("Hours per day, by tag", data: data.getHourlData(from: viewFilter), scrollable: viewFilter == 1 )
                        .frame(height: 200)
                    EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedHourlData(from: viewFilter), unit: "HR")
                    EventsDataSummaries.ActivityPerTag(data:        data.getCompressedHourlData(from: viewFilter), unit: "HR")
                    
                    Seperator(orientation: .horizontal)
                    
                    ActivitiesPerDay("Events per day, by tag", data: data.getTagData(from: viewFilter), scrollable: viewFilter == 1 )
                        .frame(height: 200)
                    EventsDataSummaries.SuperlativeEvents(data:     data.getCompressedTagData(from: viewFilter), unit: "")
                    EventsDataSummaries.ActivityPerTag(data:        data.getCompressedTagData(from: viewFilter), unit: "")
                    
                    Seperator(orientation: .horizontal)
                }
            }
        }.id( DataPageView.DataBookMark.Events.rawValue )
    }
    
}
