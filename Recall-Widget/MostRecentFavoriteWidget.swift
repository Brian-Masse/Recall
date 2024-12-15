//
//  Recall_Widget.swift
//  Recall-Widget
//
//  Created by Brian Masse on 12/13/24.
//

import WidgetKit
import SwiftUI
import UIUniversals
import AppIntents

//MARK: RandomizeFavoriteWidgetIntent
struct RandomizeFavoriteWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Randomize Events"
    static var description: LocalizedStringKey = "Choose to show your most recent favorite, or a random favorite"
    
    @Parameter(title: "Randomize")
    var randomize: Bool?
    
}

//MARK: TimelineProvider
struct MostRecentWidgetTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> RecallWidgetCalendarEvent {
        .init(title: "Favorite Evnent 🤩",
              notes: "Great Time",
              tag: "Tag")
    }
    
    func snapshot(for configuration: RandomizeFavoriteWidgetIntent, in context: Context) async -> RecallWidgetCalendarEvent {
        RecallWidgetCalendarEvent(title: "Favorite Evnent 🤩",
                                  notes: "Great Time",
                                  tag: "Tag")
    }

//    MARK: createTimeline
    func timeline(for configuration: RandomizeFavoriteWidgetIntent, in context: Context) async -> Timeline<RecallWidgetCalendarEvent> {
        
//        if the user has selected to randomize the favorite events
//        pull all the favorite events from the local storage,
//        pick a random event, and reload the timeline every hour
        if configuration.randomize ?? false {
            
            var entry = RecallWidgetCalendarEvent(title: RecallWidgetCalendarEvent.blank)
            if let allFavoriteEvents = WidgetStorage.shared.retrieveEvents(for: WidgetStorageKeys.favoriteEvents) {
                entry = allFavoriteEvents.randomElement() ?? entry
            }
            
            return Timeline(entries: [entry],
                            policy: .after(.now + 1))
           
//        otherwise just read the most recent favorite event, and display that
        } else {
            
            var entry = RecallWidgetCalendarEvent(title: RecallWidgetCalendarEvent.blank)
            if let mostRecentFavoriteEvent = WidgetStorage.shared.retrieveEvent(for: WidgetStorageKeys.recentFavoriteEvent) {
                entry = mostRecentFavoriteEvent
            }
            
            return Timeline(entries: [entry],
                            policy: .never)
        }
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
        .widgetURL(URL(string: "recall/favoriteEvent/\(event.id)"))
    }
}

//MARK: MostRecentFavoriteWidget
struct MostRecentFavoriteWidget: Widget {
    let kind = WidgetStorageKeys.widgets.mostRecentFavoriteEvent.rawValue
    
    var body: some WidgetConfiguration {
        
        AppIntentConfiguration(kind: kind,
                               provider: MostRecentWidgetTimelineProvider()) { entry in
            MostRecentFavoriteWidgetView(event: entry)
                .containerBackground(.fill, for: .widget)
        }
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Favorite Event")
        .description("Showcase your most recent favorite event, or cycle through all your favorite events")
    }
}

//MARK: Preview
#Preview(as: .systemSmall) {
    MostRecentFavoriteWidget()
} timeline: {
    RecallWidgetCalendarEvent(title: "test title title title", notes: "test notes")
}
