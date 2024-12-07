//
//  Recall_Widget.swift
//  Recall-Widget
//
//  Created by Brian Masse on 12/13/24.
//

import WidgetKit
import SwiftUI
import UIUniversals

//MARK: TimelineProvider
struct MostRecentWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecallWidgetCalendarEvent {
        .init(title: "placeholder")
    }

    func getSnapshot(in context: Context, completion: @escaping (RecallWidgetCalendarEvent) -> ()) {
        let event = RecallWidgetCalendarEvent(title: "snapshot")
        completion(event)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        var entry = RecallWidgetCalendarEvent(title: "no favorites")
        if let mostRecentFavoriteEvent = WidgetStorage.shared.retrieveEvent(for: WidgetStorageKeys.recentFavoriteEvent) {
            entry = mostRecentFavoriteEvent
        }
        
        let timeline = Timeline(entries: [entry],
                                policy: .after(.now + 1 * Constants.HourTime))
        completion(timeline)
    }
}

//MARK: WidgetView
struct MostRecentFavoriteWidgetView : View {
    var event: MostRecentWidgetTimelineProvider.Entry

    var body: some View {
        WidgetEventView(event: event)
            .padding(7)
            .background()
    }
}

//MARK: RecallWidget
struct MostRecentFavoriteWidget: Widget {
    let kind = WidgetStorageKeys.widgets.mostRecentFavoriteEvent.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MostRecentWidgetTimelineProvider()) { entry in
            MostRecentFavoriteWidgetView(event: entry)
                .containerBackground(.fill, for: .widget)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemSmall) {
    MostRecentFavoriteWidget()
} timeline: {
    RecallWidgetCalendarEvent(title: "test title title title", notes: "test notes")
}
