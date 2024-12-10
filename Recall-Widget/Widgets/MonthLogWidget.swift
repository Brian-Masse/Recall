//
//  MonthLogWidget.swift
//  Recall
//
//  Created by Brian Masse on 12/15/24.
//

import Foundation
import WidgetKit
import SwiftUI
import AppIntents
import UIUniversals

struct MonthlyLogEntry: TimelineEntry {
    let date: Date = .now
    var data: [Int]
}

//MARK: TimelineProvider
struct MonthlyLogTimelineProvider: TimelineProvider {
    private var fillerData: [Int] {
        var data = [Int](repeatElement(0, count: 31))
        let currentDay = Calendar.current.component(.day, from: .now)
        
        for i in 0..<currentDay {
            let random = Int.random(in: 0...15)
            data[i] = random
        }
        return data
    }
    
    func placeholder(in context: Context) -> MonthlyLogEntry {
        .init(data: fillerData)
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (MonthlyLogEntry) -> Void) {
        let entry: MonthlyLogEntry = .init(data: fillerData)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<MonthlyLogEntry>) -> Void) {
        var entry = MonthlyLogEntry(data: [])
        let currentMontlyLogEntries = WidgetStorage.shared.retrieveList(for: WidgetStorageKeys.currentMonthLog)
        if !currentMontlyLogEntries.isEmpty {
            entry.data = currentMontlyLogEntries
        }
        
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

//MARK: MostRecentFavoriteWidget
struct MonthlyLogWidget: Widget {
    let kind = WidgetStorageKeys.widgets.monthlyLog.rawValue
    
    var body: some WidgetConfiguration {
        
        StaticConfiguration(kind: kind,
                            provider: MonthlyLogTimelineProvider()) { entry in
            MonthlyLogWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Monthly Log")
        .description("Showcase the recalled events over the past month")
    }
}


//MARK: WidgetView
struct MonthlyLogWidgetView : View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var entry: MonthlyLogEntry
    
    private var monthLabel: String {
        let formatter = Date.FormatStyle().month(.wide).year(.twoDigits)
        return Date.now.formatted(formatter)
    }
    
    @ViewBuilder
    private func makeDay(_ day: Int, in width: Double) -> some View {
        UniversalText("\(day + 1)", size: Constants.UISmallTextSize, font: Constants.mainFont)
            .foregroundStyle( entry.data[day] < 2 ? (colorScheme == .light ? .black : .white) : .black )
            .frame(width: width, height: width)
            .background {
                RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius - 15)
                    .universalStyledBackgrond(.accent, onForeground: true)
                    .opacity( Double(entry.data[day]) / 13 )
                

            }
    }
    
    @ViewBuilder
    private func makeMonth(in geo: GeometryProxy) -> some View {
        let startOfMonth: Date = .now.getStartOfMonth()
        let daysInMonth: Int = startOfMonth.getDaysInMonth()
        let firstDayOfWeek = Calendar.current.component(.weekday, from: startOfMonth) - 1
        
        let rowCount = ceil(Double(daysInMonth + firstDayOfWeek) / 7)
        
        let spacing: Double = 2
        let width = (geo.size.width - spacing * 6) / 7
        
        VStack(alignment: .leading, spacing: spacing) {
            ForEach( 0..<Int(rowCount), id: \.self ) { row in
                
                HStack(spacing: spacing) {
                    ForEach( 0..<7, id: \.self ) { col in
                        let day = row * 7 + col  - firstDayOfWeek
                        let date = startOfMonth + Constants.DayTime * Double(day)
                        
                        if day < daysInMonth && day >= 0 {
                            makeDay(day, in: width)
                                .opacity( date > Date.now  ? 0.5 : 1)
                        } else {
                            Rectangle()
                                .frame(width: width, height: width)
                                .foregroundStyle(.clear)
                        }
                    }
                }
            }
        }
    }

//    MARK: WidgetViewBody
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                UniversalText( monthLabel, size: Constants.UISubHeaderTextSize, font: Constants.mainFont )
                
                makeMonth(in: geo)
            }
        }
        .padding(10)
        .background()
    }
}

//MARK: Preview
//#Preview(as: .systemSmall) {
//    MonthlyLogWidget()
//} timeline: {
//    
////    MonthlyLogEntry(data: data)
//}
