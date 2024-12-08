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
        .init(title: "Favorite Evnent 🤩",
              notes: "Great Time",
              tag: "Tag")
    }

    func getSnapshot(in context: Context, completion: @escaping (RecallWidgetCalendarEvent) -> ()) {
        let event = RecallWidgetCalendarEvent(title: "Favorite Evnent 🤩",
                                              notes: "Great Time",
                                              tag: "Tag")
        completion(event)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        var entry = RecallWidgetCalendarEvent(title: RecallWidgetCalendarEvent.blank)
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
        Group {
            if event.title == RecallWidgetCalendarEvent.blank {
                WidgetPlaceholderView(icon: "circle.rectangle.filled.pattern.diagonalline",
                                      message: "No Favorites",
                                      subtext: "Favorited events on your calendar will appear here")
            } else {
                WidgetEventView(event: event)
            }
        }
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
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Favorite Event")
        .description("Showcase your most recent favorite event, or cycle through all your favorite events")
    }
}

#Preview(as: .systemSmall) {
    MostRecentFavoriteWidget()
} timeline: {
    RecallWidgetCalendarEvent(title: "test title title title", notes: "test notes")
}
