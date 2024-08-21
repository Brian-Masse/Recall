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
    
    let scale: Double = 200
    
    private struct CollisionRecord {
        let forwardCollisions: ClosedRange<Int>
        let backwardCollisions: ClosedRange<Int>
    }
    
    private func checkCollisions(between startTime1: Date, endTime1: Date,
                                 and startTime2: Date) -> Bool {
        return startTime2 >= startTime1 && startTime2 <= endTime1
    }
    
    private func mapEvents() -> [ CollisionRecord ] {
        
        var records: [CollisionRecord] = []
        
        var i = 0
        
        while i < events.count {
            
            var event = events[i]
            
//            get backward collision record
            var f = i
            
            var collisionCount = 0
            var previousLowerBound = f
            var previousUpperBound = f
            
//            if f != 0 {
            
                while ( f != 0 ) {
                 
                    if i == 3 {  }
                    
                    
                    if checkCollisions(between: events[f - 1].startTime, endTime1: events[f - 1].endTime, and: event.startTime ) {
                        previousLowerBound = f - 1
                        collisionCount += 1
                    }
                    
                    f -= 1
                }
//            }
            
            //get forward collision record
            let lowerBound = i
            var upperBound = i
            
            if i == events.count - 1 { break }
            
            
            var colliding: Bool = checkCollisions(between: event.startTime,
                                                  endTime1: event.endTime,
                                                  and: events[i + 1].startTime)
            
            while colliding {
                
                i += 1
                
                upperBound = i
                
                if i == events.count - 1 { break }
                
                var newStartTime = events[i].startTime
                var newEndTime = min( event.endTime, events[i].endTime )
                
                colliding = checkCollisions(between: newStartTime,
                                            endTime1: newEndTime,
                                            and: events[i + 1].startTime)
                
            }

            let collisionRecord = CollisionRecord(forwardCollisions: lowerBound...upperBound,
                                                  backwardCollisions: collisionCount...previousUpperBound - previousLowerBound)
            records.append(collisionRecord)
            
            i += 1
        }
        
        return records
    }
    
    
    private func getLength(of event: TestEvent) -> Double {
        
        let difference =  event.endTime.timeIntervalSince(event.startTime)
        return difference / scale
        
    }
    
    private func getVerticalOffset(of event: TestEvent, relativeTo startTime: Date) -> Double {
        
        let difference = event.startTime.timeIntervalSince(startTime)
        return difference / scale
        
    }
    
    
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
        .padding()
    }
    
    @ViewBuilder
    private func makeEvents(from range: ClosedRange<Int>, backwardCollisions: ClosedRange<Int>, in geo: GeometryProxy) -> some View {
        
        HStack(alignment: .top) {
        
            if backwardCollisions.upperBound - backwardCollisions.lowerBound != 0 {
             
//                ForEach( backwardCollisions.lowerBound..<backwardCollisions.upperBound, id: \.self ) { i in
//                    
//                    HStack {
//                        Spacer()
//                    }
//
//                    .frame(height: 100)
//                    .background(.blue)
//                    .opacity(0.5)
//                    
//                }
                
                let forwardCollisionCount = range.count
                let ratio = Double(backwardCollisions.lowerBound) / Double(backwardCollisions.upperBound)
                
                Spacer(minLength: geo.size.width * ratio )
                
            }
            
            ForEach( range, id: \.self ) { i in
             
                makeEvent(events[i])
                    .alignmentGuide(VerticalAlignment.top) { _ in
                        
                        -CGFloat(getVerticalOffset(of: events[i], relativeTo: events[range.lowerBound].startTime))
                        
                    }
                
            }
        }
    }
    
    
    var body: some View {
        
        let records = mapEvents()
        let startOfDay = Date.now.resetToStartOfDay()
        
        GeometryReader { geo in
         
            ZStack {
                    
                ForEach( 0..<records.count, id: \.self ) { i in
                    Text( "\(records[i].backwardCollisions )" )
                    makeEvents(from: records[i].forwardCollisions, backwardCollisions: records[i].backwardCollisions, in: geo)
                    
                        .offset(y:  getVerticalOffset(of: events[records[i].forwardCollisions.lowerBound],
                                                      relativeTo: startOfDay) )
                    
                }
                
            
                
                Text("hi!")
            }
        }
    }
    
}

#Preview {
    
    let hour: Double = 60 * 60
    
//    let day =
    
    let events: [TestEvent] = [
        .init(startTime: .now, endTime: .now + hour * 4),
        .init(startTime: .now + hour * 1, endTime: .now + hour * 2),
        .init(startTime: .now + hour * 1.5, endTime: .now + hour * 2),
        
        
        .init(startTime: .now + hour * 2.5, endTime: .now + hour * 7),
        .init(startTime: .now + hour * 5, endTime: .now + hour * 7),
        
        .init(startTime: .now + hour * 9, endTime: .now + hour * 10)
    ]
    
    return TestCalendarView(events: events)
    
}
