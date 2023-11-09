//
//  FavoritesPageView.swift
//  Recall
//
//  Created by Brian Masse on 11/8/23.
//

import Foundation
import SwiftUI

struct FavoritesPageView: View {
    
    
//    MARK: Vars
    let events: [RecallCalendarEvent]
    
    @State var filteredEvents: [RecallCalendarEvent] = []
    
    @State var dates: [Date] = []
    @State var grouping: Calendar.Component = .month
    
//    MARK: Class Methods
    private func setup() {
        filteredEvents = filterEvents()
        dates = getUniqueDates(filteredEvents: filteredEvents)
    }
    
    private func filterEvents() -> [RecallCalendarEvent] {
        events.filter { event in event.isFavorite }
    }
    
    private func getUniqueDates(filteredEvents: [RecallCalendarEvent]) -> [Date] {
        var dates: [Date] = []
        for event in filteredEvents {
            if !dates.contains(where: { date in date.matches(event.startTime, to: grouping) }) {
                dates.append(event.startTime)
            }
        }
        return dates
    }

    
//    MARK: ViewBuilders
    struct DateCategory: View {
        
        private func filterEvents( to date: Date, in filteredEvents: [RecallCalendarEvent] ) -> [RecallCalendarEvent] {
            filteredEvents.filter { event in
                event.startTime.matches(date, to: grouping)
    //            let comp = Calendar.current.component(grouping, from: event.startTime)
            }
        }
        
        private func makeDateLabel(date: Date) -> String {
            switch grouping {
            case .day: return date.formatted(date: .abbreviated, time: .omitted)
            case .month: return date.formatted(.dateTime.month().year(.twoDigits))
            case .year: return date.formatted(.dateTime.year())
            default: return date.formatted(date: .abbreviated, time: .omitted)
            }
        }
        
        let date: Date
        let filteredEvents: [RecallCalendarEvent]
        let events: [RecallCalendarEvent]
        let geo: GeometryProxy
        
        @Binding var grouping: Calendar.Component
        @State var showingFullSection: Bool = true
        
        var body: some View {
            let groupEvents = filterEvents(to: date, in: filteredEvents)
            
            VStack(alignment: .leading) {
                
                HStack {
                    UniversalText( makeDateLabel(date: date), size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                    Spacer()
                    
                    Image(systemName: showingFullSection ? "arrow.up" : "arrow.down")
                        .padding(5)
                        .padding(.horizontal)
                        .secondaryOpaqueRectangularBackground(0)
                        .onTapGesture {
                            withAnimation { showingFullSection.toggle() }
                        }
                }
                
                if showingFullSection {
                    ForEach( groupEvents ) { event in
                        CalendarEventPreviewContentView(event: event,
                                                        events: events,
                                                        width: geo.size.width - 50,
                                                        height: 100,
                                                        allowTapGesture: true)
                    }
                }
            }
        }
        
    }
    
    @ViewBuilder
    private func makeSeperator() -> some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(.gray)
            .opacity(0.5)
    }
    
    @ViewBuilder
    private func makeIndividualGroupingSelector(title: String, icon: String, selection: Calendar.Component) -> some View {
        HStack {
            Spacer()
            UniversalText( title, size: Constants.UIDefaultTextSize, font: Constants.mainFont, wrap: false, scale: true )
            Image(systemName: icon)
            Spacer()
        }
        .if( grouping == selection ) { view in view.tintRectangularBackground() }
        .if( grouping != selection ) { view in view.secondaryOpaqueRectangularBackground() }
        .onTapGesture { withAnimation { grouping = selection }}
    }
    
    @ViewBuilder
    private func makeGroupingSelector() -> some View {
        VStack(alignment: .leading) {
            UniversalText( "Group Events", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            HStack {
                makeIndividualGroupingSelector(title: "year", icon: "book.pages", selection: .year)
                makeIndividualGroupingSelector(title: "month", icon: "calendar", selection: .month)
                makeIndividualGroupingSelector(title: "day", icon: "calendar.day.timeline.left", selection: .day)
            }
        }
    }
    
//    MARK: Body
    var body: some View {
        
        GeometryReader { geo in
            VStack(alignment: .leading) {
                ScrollView {
                    VStack(alignment: .leading) {
                        
                        makeGroupingSelector()
                            .padding(.bottom, 7)
                        
                        ForEach( dates.sorted(by: { date1, date2 in date1 > date2 }), id: \.timeIntervalSince1970 ) { date in
                            
                            DateCategory(date: date,
                                         filteredEvents: filteredEvents,
                                         events: events,
                                         geo: geo,
                                         grouping: $grouping)
                            
                            makeSeperator()
                                .padding(.bottom, 7)
                        }
                    }
                    .padding(.bottom, Constants.UIBottomOfPagePadding)
                }
            }
        }.onChange(of: grouping) { newValue in
            self.dates = getUniqueDates(filteredEvents: filteredEvents)
        }
        .onAppear { setup() }
    }
}
