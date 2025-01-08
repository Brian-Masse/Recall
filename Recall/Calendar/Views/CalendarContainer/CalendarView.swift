//
//  Test.swift
//  Recall
//
//  Created by Brian Masse on 8/21/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct TestEvent {
    let startTime: Date
    let endTime: Date
}


struct CalendarView: View {
    
//    MARK: CollisionRecord
//    forward collisions stores the indicies of a group of events that all collide along a shared y-level
//    ie. a horizontal line can be drawn through them
//    backwardCollisions stores the number of backwards collisions (lowerbound), and the difference in the index of the first backwards collision
//    to the node checking backwardsCollisions
    private struct CollisionRecord {
        let forwardCollisions: ClosedRange<Int>
        let backwardsCollisionIndicies: [Int]
        let backwardCollisions: ClosedRange<Int>
    }
    
    
    static private func checkCollisions(between startTime1: Date, endTime1: Date,
                                 and startTime2: Date, endTime2: Date) -> Bool {
        (startTime1 > startTime2 && startTime1 < endTime2) ||
        (endTime1 > startTime2 && endTime1 < endTime2) ||
        
        (startTime2 > startTime1 && startTime2 < endTime1) ||
        (endTime2 > startTime1 && endTime2 < endTime1) ||
        
        (startTime1 == startTime2 && endTime1 == endTime2)
    }
    
//    MARK: Map Events
//    map events takes the events and creates a series of collisions records
    static private func mapEvents(with events: [RecallCalendarEvent]) -> [ CollisionRecord ] {
        
        var records: [CollisionRecord] = []
        
//        a manual iterator is used such that certaine vents can be 'skipped over',
//        this happens when they belong to a forwards collision group
        var i = 0
        while i < events.count {
            let currentEvent = events[i]
            
//            get backwardCollisionRecord
//            go backward and anytime there is a collision with the currentEvent, record it
            var f = max(0, i - 1)
            var collisions: [Int] = []
            var previousLowerBound = i
            
            var colliding: Bool = checkCollisions(between: events[f].startTime,
                                                  endTime1: events[f].endTime,
                                                  and: events[i].startTime,
                                                  endTime2: events[i].endTime )
            
            if colliding { collisions.append(f) }
            
            while f != 0 && colliding {
                let previousEvent = events[f - 1]
                
                colliding = checkCollisions(between: previousEvent.startTime,
                                   endTime1: previousEvent.endTime,
                                   and: events[f].startTime,
                                   endTime2: events[f].endTime )
                
                if colliding { previousLowerBound = f - 1 }
                
                if checkCollisions(between: previousEvent.startTime,
                                   endTime1: previousEvent.endTime,
                                   and: currentEvent.startTime,
                                   endTime2: currentEvent.startTime) { collisions.append(f - 1) }
                
                f -= 1
            }
            
            let backwardsCollisionRecord = previousLowerBound...max(previousLowerBound,i - 1)
           
//            get forwardCollisionRecord
//            see how many (if any) events the current event shares a common collision with
//            ie. determine how many events a horizontal line can be drawn through to include the currentEvent
            let lowerBound = i
            var upperBound = i
            
            colliding = i < events.count - 1 && checkCollisions(between: currentEvent.startTime,
                                                                endTime1: currentEvent.endTime,
                                                                and: events[i + 1].startTime,
                                                                endTime2: events[i + 1].endTime)
            
            while colliding {
                i += 1
                upperBound = i
                
                if i == events.count - 1 { break }
                
//                take the smallest intersection between the two colliding events
                let newStartTime = events[i].startTime
                let newEndTime = min( currentEvent.endTime, events[i].endTime )
                
                colliding = checkCollisions(between: newStartTime,
                                            endTime1: newEndTime,
                                            and: events[i + 1].startTime,
                                            endTime2: events[i + 1].endTime)
            }

            
            let collisionRecord = CollisionRecord(forwardCollisions: lowerBound...upperBound,
                                                  backwardsCollisionIndicies: collisions,
                                                  backwardCollisions: backwardsCollisionRecord)
            
            records.append(collisionRecord)
            
            i += 1
        }
        
        return records
    }
    
    
//    MARK: Sizing Functions
//    takes the length of an event and returns a length in pixels
    private func getLength(of event: RecallCalendarEvent) -> Double {
        
        let difference =  event.endTime.timeIntervalSince(event.startTime)
        return difference / viewModel.scale
        
    }
    
//    take the distance between two events and return a length in pixels
    private func getVerticalOffset(of event: RecallCalendarEvent, relativeTo startTime: Date) -> Double {
        if event.isInvalidated { return 0}
        let difference = event.startTime.timeIntervalSince(startTime) - (startHour * Constants.HourTime)
        return difference / viewModel.scale
        
    }
    
    
//    MARK: Event Builder
    @ViewBuilder
    private func makeEvent( _ event: RecallCalendarEvent ) -> some View {
        HStack {
            VStack {
                Text("\(event.startTime.formatted())")
                Text("\(event.endTime.formatted())")
            }
            
            Spacer()
        }
        .frame(height: getLength(of: event))
        .background(.red)
        .padding(.horizontal, 2.5)
        .border(.blue)
    }
    
//    MARK: EventCollection
    @MainActor
    @ViewBuilder
    private func makeEventCollection(from collisionRecord: CollisionRecord, in geo: GeometryProxy) -> some View {
        
        HStack(alignment: .top, spacing: 0) {
            
            let ratio: Double       = 1 / Double(collisionRecord.backwardCollisions.count)
            let lastCollisionIndex  = collisionRecord.backwardsCollisionIndicies.last ?? 0
            let indexToRender       = (lastCollisionIndex - 1 + collisionRecord.backwardCollisions.count - collisionRecord.forwardCollisions.lowerBound) % collisionRecord.backwardCollisions.count
            
            ForEach( 0..<collisionRecord.backwardCollisions.count, id: \.self ) { i in
                if i == abs(indexToRender) || collisionRecord.backwardsCollisionIndicies.count == 0 {
                    ForEach( collisionRecord.forwardCollisions, id: \.self ) { i in
                        
                        let index = min(events.count - 1, i)
                        let event = events[index]
                        let startTime = events[collisionRecord.forwardCollisions.lowerBound].startTime
                            
                        CalendarEventPreviewView(event: event,
                                                 events: events,
                                                 includeGestures: includeGestures)
                        .id(event._id)
                        .matchedGeometryEffect(id: event._id, in: namespace)
//                        .transition(.blurReplace)
                        .frame(height: getLength(of: event))
                        .alignmentGuide(VerticalAlignment.top) { _ in
                            -CGFloat(getVerticalOffset(of: events[index],
                                                       relativeTo: startTime))
                        }
                        .opacity(highlightEvent == nil ? 1 : ( highlightEvent!.title == events[i].title ? 1 : 0.25 ))
                    }
                } else if collisionRecord.backwardsCollisionIndicies.contains(i + collisionRecord.backwardCollisions.lowerBound) {
                    Rectangle()
                        .frame(width: geo.size.width * ratio, height: 50)
                        .foregroundStyle(.clear)
                }
            }
        }
    }
    
//    MARK: DateLabel
    @ViewBuilder
    private func makeDateLabel() -> some View {
        
    }
    
//    MARK: Vars
    @ObservedObject private var viewModel = RecallCalendarContainerViewModel.shared
    @Namespace private var namespace
    
    private let events: [RecallCalendarEvent]
    private let day: Date
    
    private let startHour: Double
    private let endHour: Int
    
    private let includeGestures: Bool
    private let highlightEvent: RecallCalendarEvent?
    
//    TODO: When the app boots, this function call runs for every single day the user has ever recorded events for
//    not sure why, but that should probably be fixed!
//    This also gets run to update every single time the user scrolls on the main vertical calendar 
    init(events: [RecallCalendarEvent], on day: Date, startHour: Double = 0, endHour: Int = 24, includeGestures: Bool = true, highlightEvent: RecallCalendarEvent? = nil) {
        self.day = day
        self.startHour = startHour
        self.endHour = endHour
        self.includeGestures = includeGestures
        self.highlightEvent = highlightEvent
        
        self.events = events
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                
                Rectangle()
                    .foregroundStyle(.clear)
                
                let records = CalendarView.mapEvents(with: events)
                let startOfDay = day.resetToStartOfDay()

                ForEach( 0..<records.count, id: \.self ) { i in
                    let record = records[i]
                    let event = events[min(events.count - 1, record.forwardCollisions.lowerBound)]
                    let eventStartHour = Calendar.current.component(.hour, from: event.startTime)
                    let eventEndHour = Calendar.current.component(.hour, from: event.endTime)
                    
                    if max(eventEndHour, eventStartHour) >= Int(startHour) &&
                        min(eventStartHour, eventEndHour) <= endHour &&
                        events.count > record.forwardCollisions.lowerBound
                    {
                        
                        let offset = getVerticalOffset(of: event, relativeTo: startOfDay)
                        
                        makeEventCollection(from: record, in: geo)
                            .offset(y: offset)
                            .zIndex(0)
                    }
                }
            }
        }
        .animation(.spring, value: events)
    }
}
