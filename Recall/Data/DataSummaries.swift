//
//  DataSummaries.swift
//  Recall
//
//  Created by Brian Masse on 7/31/23.
//

import Foundation
import SwiftUI

//MARK: Events DataSummaries
//All the data passed to summaries should be compressed
//this means that instead of passing nodes for every indivudal calendar event, you compress them into their common tags
//the data is seperated so it can be better plotted on the graphs
//the indivudal DataSection that summary is being managed by should make sure its passing the right data in
struct EventsDataSummaries {
    
//    This describes the daily average, either hours or tags per day, that a person has
    struct DailyAverage: View {
        
        let data: [DataNode]
        let unit: String
        
        var body: some View {
            
            let fullTimePeriod = Date.now.timeIntervalSince( RecallModel.index.earliestEventDate ) / Constants.DayTime
            let averageSummaryListContent = data.compactMap { node in
                DataSummaryList.Data(label: node.category, content: "\( (node.count / fullTimePeriod).round(to: 2) ) " + unit )
            }
            
            DataSummaryList(content: averageSummaryListContent, striped: true)
                .hideableDataCollection("Average Activity", defaultIsHidden: true)
        }
    }

//    This tells the user which events they engage in most / least
    struct SuperlativeEvents: View {
        
        let data: [DataNode]
        let unit: String
        
        var body: some View {
            DataSummaryList(content: [
                .init(label: "Most Frequent Event", content: "\( data.last?.category ?? "?") (\( data.last?.count.round(to: 2) ?? 0 ) \(unit))"),
                .init(label: "Least Frequent Event", content: "\( data.first?.category ?? "?") (\( data.first?.count.round(to: 2) ?? 0 ) \(unit))")
            ])
        }
    }
    
//    This is a full breakdown of how much activity each tag has
    struct ActivityPerTag: View {
        let data: [DataNode]
        let unit: String
        
        var body: some View {
            let dataSummaryListContent = data.compactMap { node in
                DataSummaryList.Data(label: node.category, content: "\(node.count.round(to: 2)) \(unit)")
            }
            
            DataSummaryList(content: dataSummaryListContent, striped: true)
                .hideableDataCollection("Full breakdown", defaultIsHidden: true)
        }
    }
}

//MARK: Goals Data Summaries
struct GoalsDataSummaries {
    
    struct GoalsMetCount: View {
        let data: [DataNode]
        
        var body: some View {
            
            let dataSummaryListContent = data.compactMap { node in
                DataSummaryList.Data(label: node.goal, content: "\(Int(node.count))")
            }
            
            DataSummaryList(content: dataSummaryListContent, striped: true)
                .hideableDataCollection("Full breakdown")
        }
    }
    
    struct GoalsMetPercentageBreakdown: View {
        let data: [DataNode]
        
        var body: some View {
            let dataSummaryListContent = data.compactMap { node in
                DataSummaryList.Data(label: node.goal, content: "\(node.count.round(to: 2))")
            }
            
            DataSummaryList(content: dataSummaryListContent, striped: true)
                .hideableDataCollection("Full Breakdown")
        }
    }
}


//MARK: Data Summary List
struct DataSummaryList: View {
    
    struct Data: Identifiable {
        let label: String
        let content: String
        
        var id: String { label + content }
    }
    
    let content: [Data]
    let striped: Bool
    
    init( content: [Data], striped: Bool = false ) {
        self.content = content
        self.striped = striped
    }
    
    var body: some View {
        
        VStack {
            ForEach(content.indices, id: \.self) { i in
                HStack {
                    UniversalText(content[i].label, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
                        .frame(maxWidth: 130, alignment: .leading)
                    
                    Spacer()
                    UniversalText(content[i].content, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                }
                .if(!striped) { view in view.padding(.bottom, 5) }
                .if(striped) { view in view.padding(.horizontal, 7) }
                .if(striped && !i.isMultiple(of: 2)) { view in
                    view.secondaryOpaqueRectangularBackground(7)
                }
            }
        }
    }
}

//MARK: Large Summary Text
struct LargeText: View {
    
    let mainText: String
    let subText: String
    
    var body: some View {
        VStack(alignment: .leading) {
            let length = mainText.removeFirst(of: ".").count
            let lengthScaling = (Constants.UISmallTextSize * Double(length - 1))
            
            HStack(alignment: .bottom) {
                UniversalText(mainText, size: Constants.UILargeTextSize * 2, font: Constants.titleFont, wrap: false, scale: true)
                UniversalText(subText, size: Constants.UITitleTextSize, font: Constants.titleFont, wrap: false, scale: true)
            }
            .padding(.top, -Constants.UITitleTextSize + lengthScaling)
            .padding(.bottom, -Constants.UIDefaultTextSize)
        }
    }
}
