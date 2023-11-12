//
//  FavoritesPageView.swift
//  Recall
//
//  Created by Brian Masse on 11/8/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct FavoritesPageView: View {
    
    let dateGroupings: [Calendar.Component ] = [ .year, .month, .day ]
    
//    MARK: Vars
    var events: [RecallCalendarEvent]
    
    @State var filteredEvents: [RecallCalendarEvent] = []
    
    @State var groupedEvents: Dictionary<Date, [RecallCalendarEvent]> = Dictionary()
    
    @State var dates: [Date] = []
    @State var grouping: Calendar.Component = .month
    
//    MARK: Class Methods
    private func setup() {
        filteredEvents = filterEvents()
        groupEvents()
    }   
    
    private func filterEvents() -> [RecallCalendarEvent] {
        events.filter { event in event.isFavorite }.sorted { event1, event2 in
            event1.startTime > event2.startTime
        }
    }
    
    private func groupEvents()  {
        groupedEvents = Dictionary()
        for event in filteredEvents {
            let dateKey = event.startTime.prioritizeComponent(grouping)
            
            if let _ = groupedEvents[dateKey] {
                groupedEvents[dateKey]!.append(event)
            } else {
                groupedEvents[dateKey] = [ event ]
            }
        }
    }
    
    private func getDates() -> [Date] {
        let dateFormatter = DateFormatter()
        
        return groupedEvents.map { key, value in key}.sorted { date1, date2 in
            date1 > date2
        }
    }
    
//    MARK: ViewBuilders
    struct DateCategory: View {
        
        let date: Date
        let groupedEvents: [RecallCalendarEvent]
        let events: [RecallCalendarEvent]
        let geo: GeometryProxy
        
        @Binding var grouping: Calendar.Component
        @State var showingFullSection: Bool = true
        
        @State var showingEventEditingView: Bool = false
        @State var showingDeletionAlert: Bool = false
        
        private func makeDateLabel(date: Date) -> String {
            switch grouping {
            case .day: return date.formatted(date: .abbreviated, time: .omitted)
            case .month: return date.formatted(.dateTime.month().year(.twoDigits))
            case .year: return date.formatted(.dateTime.year())
            default: return date.formatted(date: .abbreviated, time: .omitted)
            }
        }
        
        var body: some View {
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
                    ForEach( groupedEvents ) { event in
                        CalendarEventPreviewContentView(event: event,
                                                        events: events,
                                                        width: geo.size.width - 50,
                                                        height: 100,
                                                        allowTapGesture: true)
                        
                        .sheet(isPresented: $showingEventEditingView) {
                            CalendarEventCreationView.makeEventCreationView(currentDay: .now,
                                                                            editing: true,
                                                                            event: event)
                        }
                        
                        .contextMenu {
//                            ContextMenuButton("edit", icon: "slider.horizontal.below.rectangle") {
//                                showingEventEditingView = true
//                            }
                            
                            ContextMenuButton("unfavorite", icon: "circle.rectangle.filled.pattern.diagonalline") {
                                event.toggleFavorite()
                            }
                            
                            ContextMenuButton("delete", icon: "trash", role: .destructive) {
                                showingDeletionAlert = true
                            }
                        }
                        .alert("delete favorite event", isPresented: $showingDeletionAlert, actions: {
                            ContextMenuButton("delete", icon: "trash", role: .destructive) { event.delete() }
                        }, message: {
                            Text("This action cannot be undone.")
                        })
                        
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
                        
                        let dates = getDates()
                        
                        ForEach( dates, id: \.self ) { date in
                            
                            DateCategory(date: date,
                                         groupedEvents: groupedEvents[date]!,
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
        }
        .onChange(of: grouping) { _ in groupEvents() }
        .onChange(of: events) {
            
            _ in groupEvents() }
        .onAppear { setup() }
    }
}
