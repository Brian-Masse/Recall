//
//  TodaysEventsWidget.swift
//  Recall
//
//  Created by Brian Masse on 12/15/24.
//

import Foundation
import WidgetKit
import SwiftUI
import AppIntents
import UIUniversals

struct RecallWidgetCalendarEventCollection: TimelineEntry {
    let date: Date = .now
    var events: [RecallWidgetCalendarEvent]
}

//MARK: TimelineProvider
struct TodaysEventsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecallWidgetCalendarEventCollection {
        .init(events: [ .init(title: "placeholder") ])
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (RecallWidgetCalendarEventCollection) -> Void) {
        let entry: RecallWidgetCalendarEventCollection = .init(events: [ RecallWidgetCalendarEvent(title: "snapshot") ])
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<RecallWidgetCalendarEventCollection>) -> Void) {
        
        let events: [RecallWidgetCalendarEvent] = WidgetStorage.shared.retrieveEvents(for: WidgetStorageKeys.todaysEvents) ?? []
        let entry: RecallWidgetCalendarEventCollection = .init(events: events)

        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

//MARK: MostRecentFavoriteWidget
struct TodaysEventsWidget: Widget {
    let kind = WidgetStorageKeys.widgets.todaysEvents.rawValue
    
    var body: some WidgetConfiguration {
        
        StaticConfiguration(kind: kind,
                            provider: TodaysEventsTimelineProvider()) { entry in
            TodaysRecallWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .configurationDisplayName("Today's Recall")
        .description("Get a preview of your most recent Recall")
    }
}


//MARK: WidgetView
struct TodaysRecallWidgetView : View {

    @Environment(\.widgetFamily) var widgetFamily
    
    let entry: RecallWidgetCalendarEventCollection
    var scale: Double { widgetFamily == .systemLarge ? 75 : 150 }
    
    func getEventLength(for event: RecallWidgetCalendarEvent) -> Double {
        event.endTime.timeIntervalSince(event.startTime) / scale
    }
    
    func getPosition(from time: Date) -> Double {
        let startOfDay = time.resetToStartOfDay()
        return ( time.timeIntervalSince(startOfDay) / scale )
    }
    
//    This function checks the start position, in pixels, of the given event if it were laied out in the first coloumn
    func getSingleColoumnLayoutPosition(for event: RecallWidgetCalendarEvent) -> Double {
//        get the position of the bottom of the first event
        let startHeight = getPosition( from: entry.events[0].startTime )
        let endHeight = getPosition(from: event.startTime)
        return endHeight - startHeight
    }
    
    @ViewBuilder
    private func makeLabels(startIndex: Int) -> some View {
        
        let formatter = Date.FormatStyle().hour(.twoDigits(amPM: .omitted))
        let startDate = entry.events[startIndex].startTime
        let increment: Double = 2 * Constants.HourTime / scale
        
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                let date = startDate + (Constants.HourTime * Double(i))
                
                UniversalText( date.formatted(formatter),
                               size: Constants.UISmallTextSize - 1,
                               font: Constants.mainFont)
                    .offset( y: increment * Double(i) )
                    .opacity(0.35)
            }
        }
    }
    
    @ViewBuilder
    private func makeCalendarPane(startIndex: Int, endIndex: Int) -> some View {
        let startEventPosition = getPosition(from: entry.events[startIndex].startTime)
        
        HStack(alignment: .top, spacing: 2) {
            makeLabels(startIndex: startIndex)
            ZStack(alignment: .top) {
                ForEach( startIndex..<endIndex, id: \.self ) { i in
                    
                    let event = entry.events[i]
                    let height = getEventLength(for: event)
                    let pos = getPosition(from: event.startTime)
                    
                    WidgetEventView(event: event, height: height - 4, showContent: true)
                        .padding(.vertical, 2)
                        .offset(y: pos - startEventPosition)
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeDividers() -> some View {
        let increment = 2 * Constants.HourTime / scale
        
        ZStack(alignment: .top) {
            Rectangle().foregroundStyle(.clear)
            
            ForEach(0..<5, id: \.self ) { i in
                Divider()
                    .offset(y: Double(i) * increment + 15)
            }
        }
    }
    
//    MARK: WidgetViewBody
    var body: some View {
        GeometryReader { geo in
            let splitIndex: Int = entry.events.firstIndex { event in
                getSingleColoumnLayoutPosition(for: event) + 50 > geo.size.height
            } ?? entry.events.count - 1
            
            HStack(alignment: .top, spacing: 5) {
                makeCalendarPane(startIndex: 0, endIndex: splitIndex)
            
                if widgetFamily != .systemSmall && splitIndex < entry.events.count {
                    makeCalendarPane(startIndex: splitIndex, endIndex: entry.events.count)
                }
            }
            .frame(height: geo.size.height, alignment: .top)
            .background(alignment: .top) { makeDividers() }
        }
        .padding(7)
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
