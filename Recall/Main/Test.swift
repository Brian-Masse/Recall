//
//  Test.swift
//  Recall
//
//  Created by Brian Masse on 8/21/24.
//

import Foundation
import SwiftUI

struct TestEvent {
    let startTime: Date
    let endTime: Date
}


struct TestCalendarView: View {
    
    let events: [TestEvent]
    
//    MARK: CollisionRecord
//    forward collisions stores the indicies of a group of events that all collide along a shared y-level
//    ie. a horizontal line can be drawn through them
//    backwardCollisions stores the number of backwards collisions (lowerbound), and the difference in the index of the first backwards collision
//    to the node checking backwardsCollisions
    private struct CollisionRecord {
        let forwardCollisions: ClosedRange<Int>
        let backwardCollisions: ClosedRange<Int>
    }
    
    
    private func checkCollisions(between startTime1: Date, endTime1: Date,
                                 and startTime2: Date) -> Bool {
        return startTime2 >= startTime1 && startTime2 <= endTime1
    }
    
//    MARK: Map Events
//    map events takes the events and creates a series of collisions records
    private func mapEvents() -> [ CollisionRecord ] {
        
        var records: [CollisionRecord] = []
        
//        a manual iterator is used such that certaine vents can be 'skipped over',
//        this happens when they belong to a forwards collision group
        var i = 0
        while i < events.count {
            
            let currentEvent = events[i]
            
//            get backwardCollisionRecord
//            go backward and anytime there is a collision with the currentEvent, record it
            var f = i
            
            var collisionCount = 0
            var previousLowerBound = f
            let previousUpperBound = f

            while ( f != 0 ) {
                let previousEvent = events[f - 1]
                
                let nextEndTime = max( previousEvent.endTime, events[min(f, i - 1)].endTime )
                
                if checkCollisions(between: previousEvent.startTime,
                                   endTime1: nextEndTime,
                                   and: currentEvent.startTime ) {
                    
                    previousLowerBound = f - 1
                    collisionCount += 1
                }
                
                f -= 1
            }
            
            let backwardsCollisionRecord = collisionCount...(previousUpperBound - previousLowerBound)
            
            
//            get forwardCollisionRecord
//            see how many (if any) events the current event shares a common collision with
//            ie. determine how many events a horizontal line can be drawn through to include the currentEvent
            
            let lowerBound = i
            var upperBound = i
            
            var colliding: Bool = i < events.count - 1 && checkCollisions(between: currentEvent.startTime,
                                                                           endTime1: currentEvent.endTime,
                                                                           and: events[i + 1].startTime)
            
            while colliding {
                
                i += 1
                
                upperBound = i
                
                if i == events.count - 1 { break }
                
//                take the smallest intersection between the two colliding events
                let newStartTime = events[i].startTime
                let newEndTime = min( currentEvent.endTime, events[i].endTime )
                
                colliding = checkCollisions(between: newStartTime,
                                            endTime1: newEndTime,
                                            and: events[i + 1].startTime)
            }

            
            let collisionRecord = CollisionRecord(forwardCollisions: lowerBound...upperBound,
                                                  backwardCollisions: backwardsCollisionRecord)
            
            records.append(collisionRecord)
            
            i += 1
        }
        
        return records
    }
    
    
//    MARK: Sizing Functions
//    takes the length of an event and returns a length in pixels
    private func getLength(of event: TestEvent) -> Double {
        
        let difference =  event.endTime.timeIntervalSince(event.startTime)
        return difference / scale
        
    }
    
//    take the distance between two events and return a length in pixels
    private func getVerticalOffset(of event: TestEvent, relativeTo startTime: Date) -> Double {
        
        let difference = event.startTime.timeIntervalSince(startTime)
        return difference / scale
        
    }
    
    
//    MARK: Event Builder
    @ViewBuilder
    private func makeEvent( _ event: TestEvent ) -> some View {
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
    }
    
//    MARK: EventCollection
    @ViewBuilder
    private func makeEventCollection(from collisionRecord: CollisionRecord, in geo: GeometryProxy) -> some View {
        
        HStack(alignment: .top, spacing: 0) {
        
//            if the current event has collided with previous events, push it forward by the correct amount
            if collisionRecord.backwardCollisions.count != 1{
                let ratio = Double(collisionRecord.backwardCollisions.lowerBound) / Double(collisionRecord.backwardCollisions.upperBound)
                
                Rectangle()
                    .frame(width: geo.size.width * ratio,
                            height: 50)
                    .foregroundStyle(.clear)
            }
                
//            render the events
            ForEach( collisionRecord.forwardCollisions, id: \.self ) { i in
             
                makeEvent(events[i])
                    .alignmentGuide(VerticalAlignment.top) { _ in
                        -CGFloat(getVerticalOffset(of: events[i],
                                                   relativeTo: events[collisionRecord.forwardCollisions.lowerBound].startTime))
                    }
            }
        }
    }
    
    @State private var scale: Double = 50
    
//    MARK: Body
    var body: some View {
        
        let records = mapEvents()
        let startOfDay = Date.now.resetToStartOfDay()
        
        VStack {
            
            Slider( value: $scale, in: 50...200 )
            
            GeometryReader { geo in
                ScrollView(.vertical) {
                    ZStack {
                        ForEach( 0..<records.count, id: \.self ) { i in
                            makeEventCollection(from: records[i], in: geo)
                                .alignmentGuide(VerticalAlignment.center) { _ in
                                    let offset = getVerticalOffset(of: events[records[i].forwardCollisions.lowerBound],
                                                                   relativeTo: startOfDay)
                                    return -offset
                                }
                            
                        }
                    }
                    .border(.blue)
//                    .scaleEffect(0.5)
                }
            }
        }
    }
}


#Preview {
    
    let hour: Double = 60 * 60

    let events: [TestEvent] = [
        .init(startTime: .now, endTime: .now + hour * 2),
        .init(startTime: .now + hour * 1, endTime: .now + hour * 4),
        .init(startTime: .now + hour * 1.5, endTime: .now + hour * 2),
        
        
        .init(startTime: .now + hour * 2.5, endTime: .now + hour * 7),
        .init(startTime: .now + hour * 5, endTime: .now + hour * 7),
        
            .init(startTime: .now + hour * 7.5, endTime: .now + hour * 10)
    ]
    
    return TestCalendarView(events: events)
    
}
