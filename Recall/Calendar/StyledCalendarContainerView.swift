//
//  StyledCalendarContainerView.swift
//  Recall
//
//  Created by Brian Masse on 2/24/24.
//

import Foundation
import SwiftUI
import UIUniversals


//This will have a very similar appearance to the actualy CalendarContainerView
//but it is designed for palces that dont need the advanced selecting and gesture
//functionality (ie. you just need the style of the container)
//because of this it will have no ContainerModel
struct StyledCalendarContainerView: View {
    
    let events: [RecallCalendarEvent]
    let currentDay: Date
    
    private let startHour: Int
    private let endHour: Int
    
    private let geo: GeometryProxy
    private let scale: CGFloat
    
    private var spacing: CGFloat { height / CGFloat( endHour - startHour ) }
    private var height: CGFloat { geo.size.height * scale }
    
    private func filterEvents() -> [RecallCalendarEvent] {
        events.filter { event in
            event.startTime.matches(currentDay, to: .day) &&
            event.startTime.matches(currentDay, to: .month) &&
            event.startTime.matches(currentDay, to: .year)
        }
    }
    
    init( at currentDay: Date, with events: [RecallCalendarEvent], from startHour: Int, to endHour: Int, geo: GeometryProxy, scale: CGFloat ) {
        
        self.currentDay = currentDay
        self.events = events
        self.startHour = startHour
        self.endHour = endHour
        self.geo = geo
        self.scale = scale
        
    }
    
    @StateObject var containerModel: CalendarContainerModel = CalendarContainerModel()
    
//    MARK: Body
    var body: some View {
        ScrollView(.vertical) {
            ZStack(alignment: .topLeading) {
                
                let filtered = filterEvents()
                
                CalendarView(day: currentDay, spacing: spacing, startHour: startHour, endHour: endHour)
                
                ForEach( filtered, id: \.self ) { event in
                    CalendarEventPreviewView(event: event,
                                             spacing: spacing,
                                             geo: geo,
                                             startHour: startHour,
                                             events: filtered)
                    .environmentObject(containerModel)
                }
                .padding(.leading, 40)
            }
            .frame(height: height)
        }
        .rectangularBackground(10, style: .transparent, stroke: true)
    }
}
