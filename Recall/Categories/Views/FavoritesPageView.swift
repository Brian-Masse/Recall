//
//  FavoritesPageView.swift
//  Recall
//
//  Created by Brian Masse on 11/8/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

struct FavoritesPageView: View {
    
    let dateGroupings: [Calendar.Component ] = [ .year, .month, .day ]
    
//    MARK: Vars
    var events: [RecallCalendarEvent]
    
    @State var dates: [Date] = []
    @State var grouping: Calendar.Component = .month
    @State var groupedEvents: Dictionary<Date, [RecallCalendarEvent]> = Dictionary()
    
    @State var dataLoaded: Bool = false
    
//    MARK: Class Methods
//    Group events goes throughs the events and collects them into data categories based on the filter selected;
//    ie. collecting al favorite events that happened in the same month
//    this should always be done asyncrounously
    private func updateGrouping() async {
        withAnimation { self.dataLoaded = false } 
        
        let filteredAndSortedEvents = await filterEvents()
        
        let groupedEvents = await groupEvents(filteredAndSortedEvents: filteredAndSortedEvents)
        
        self.dates = await getDates(from: groupedEvents)
        self.groupedEvents = groupedEvents

        await RecallModel.wait(for: 0.2)
        
        withAnimation { self.dataLoaded = true }
    }
    
    
    private func filterEvents() async -> [RecallCalendarEvent] {
        events.filter { event in event.isFavorite }.sorted { event1, event2 in
            event1.startTime > event2.startTime
        }
    }
    
    private func groupEvents(filteredAndSortedEvents: [RecallCalendarEvent]) async -> Dictionary<Date, [RecallCalendarEvent]> {
        var tempDic: Dictionary<Date, [RecallCalendarEvent]> = Dictionary()
        
        for event in filteredAndSortedEvents {
            let dateKey = event.startTime.prioritizeComponent(grouping)
            
            if let _ = tempDic[dateKey] {
                tempDic[dateKey]!.append(event)
            } else {
                tempDic[dateKey] = [ event ]
            }
        }
        
        return tempDic
    }
    
    private func getDates(from groupedEvents: Dictionary<Date, [RecallCalendarEvent]>) async -> [Date] {
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
        
        @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
        @Namespace private var namespace
        
        let grouping: Calendar.Component
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
                    
                    LargeRoundedButton("", to: "",
                                       icon: "arrow.up", to: "arrow.down",
                                       small: true,
                                       foregroundColor: nil,
                                       style: .secondary)
                    { showingFullSection } action: { showingFullSection.toggle() }
                }
                
                if showingFullSection {
                    ForEach( groupedEvents ) { event in
                        CalendarEventPreviewContentView(event: event, events: events)
                            .contextMenu {
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
                        
                            .safeZoomMatch(id: event.identifier(), namespace: namespace)
                            .onTapGesture {
                                coordinator.push( .recallEventView(id: event.identifier(), event: event, events: [event], Namespace: namespace) )
                            }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeIndividualGroupingSelector(title: String, icon: String, selection: Calendar.Component) -> some View {
        HStack {
            Spacer()
            UniversalText( title, size: Constants.UIDefaultTextSize, font: Constants.mainFont, wrap: false, scale: true )
            RecallIcon(icon)
            Spacer()
        }
        .if( grouping == selection ) { view in view.rectangularBackground(style: .accent, foregroundColor: .black) }
        .if( grouping != selection ) { view in view.rectangularBackground(style: .secondary) }
        .onTapGesture { if dataLoaded { withAnimation { grouping = selection }}}
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
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading) {
                    makeGroupingSelector()
                        .padding(.bottom, 7)
                        
                    if dataLoaded {
                        if !dates.isEmpty {
                            ForEach( dates, id: \.self ) { date in
                                
                                DateCategory(date: date,
                                             groupedEvents: groupedEvents[date]!,
                                             events: events,
                                             geo: geo,
                                             grouping: grouping)
                                
                                Divider()
                                    .padding(.bottom, 7)
                            }
                        } else {
                            makeSectionFiller(icon: "circle.rectangle.filled.pattern.diagonalline",
                                              message: "No Favorites yet. Favorite an event on your calendar to view it here") { }
                        }
                    } else {
                        CollectionLoadingView(count: 5, height: 100)
                            .opacity(dataLoaded ? 0 : 1)
                        
                    }
                }
                .padding(.bottom, Constants.UIBottomOfPagePadding)
            }
        }
        .onChange(of: grouping) { Task { await updateGrouping() } }
        .onChange(of: events)   { Task { await updateGrouping() } }
        .task { await updateGrouping() }
    }
}
