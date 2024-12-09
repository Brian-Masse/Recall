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


struct MonthlyLogEntry: TimelineEntry {
    let date: Date = .now
    var data: [Int]
}

//MARK: TimelineProvider
struct MonthlyLogTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthlyLogEntry {
        .init(data: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (MonthlyLogEntry) -> Void) {
        let entry: MonthlyLogEntry = .init(data: [])
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

//MARK: WidgetView
struct MonthlyLogWidgetView : View {
    var entry: MonthlyLogEntry

    var body: some View {
        Group {
            Text("\(entry.data)")
        }
        .padding(7)
        .background()
    }
}

//MARK: MostRecentFavoriteWidget
struct MonthlyLogWidget: Widget {
    let kind = WidgetStorageKeys.widgets.monthlyLog.rawValue
    
    var body: some WidgetConfiguration {
        
        StaticConfiguration(kind: kind,
                            provider: MonthlyLogTimelineProvider()) { entry in
            MonthlyLogWidgetView(entry: entry)
        }
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Favorite Event")
        .description("Showcase your most recent favorite event, or cycle through all your favorite events")
    }
}

//MARK: Preview
#Preview(as: .systemSmall) {
    MonthlyLogWidget()
} timeline: {
    RecallWidgetCalendarEvent(title: "test title title title", notes: "test notes")
}
