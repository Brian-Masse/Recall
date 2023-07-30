//
//  CalendarContinerView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI

struct CalendarContainer: View {
    
//   MARK: Calendar View
    private struct CalendarView: View {
        
        @ViewBuilder
        func makeTimeMarker(hour: CGFloat, label: String, color: Color) -> some View {
            VStack {
                HStack(alignment: .top) {
                    UniversalText( label, size: Constants.UISmallTextSize, lighter: true  )
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(color)
                }
                .id( Int(hour.rounded(.down)) )
                .offset(y: CGFloat(hour) * spacing )
                Spacer()
            }
        }
        
        private func makeHourLabel( from hour: Int ) -> String {
            if hour == 0 { return "12AM" }
            if hour < 12 { return "\(hour)AM" }
            if hour == 12 { return "12PM" }
            if hour > 12 { return "\(hour - 12)PM" }
            return ""
        }
        
        let day: Date
        let hoursToDisplay: CGFloat
        let spacing: CGFloat
        
        var body: some View {
            ZStack(alignment: .top) {
                ForEach(0..<Int(hoursToDisplay), id: \.self) { hr in
                    makeTimeMarker(hour: CGFloat(hr), label: makeHourLabel(from: hr).uppercased(), color: .gray.opacity(0.4))
                }
                
                makeTimeMarker(hour: CGFloat(Date.now.getHoursFromStartOfDay()), label: "", color: .red)
            }
        }
    }
    
//    MARK: Dates Preview
    struct DatesPreview: View {
        
        @ViewBuilder
        func makeDateSelector(_ date: Date) -> some View {
            UniversalText( "\(Calendar.current.component(.day, from: date))", size: Constants.UIDefaultTextSize)
                .padding(7)
                .onTapGesture { withAnimation { currentDay = date } }
//                .frame(width: 30)
        }
        
        @Binding var currentDay: Date
        
        var body: some View {
            
            HStack {
                Image(systemName: "chevron.left")
                    .padding(7)
                    .rectangularBackgorund()
                    .onTapGesture { currentDay -= Constants.DayTime }
                Spacer()
                
                makeDateSelector( currentDay - 2 * Constants.DayTime )
                makeDateSelector( currentDay - 1 * Constants.DayTime )
                
                UniversalText( "\(Calendar.current.component(.day, from: currentDay))", size: Constants.UIDefaultTextSize, true )
                    .padding()
                    .foregroundColor(Colors.tint)
                    .rectangularBackgorund()
                
                makeDateSelector( currentDay + 1 * Constants.DayTime )
                makeDateSelector( currentDay + 2 * Constants.DayTime )
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .padding(7)
                    .rectangularBackgorund()
                    .onTapGesture { currentDay += Constants.DayTime }
            }
        }
    }
    
//    MARK: Gestures
//    This doesn't do anything right now, because the horizontal gestures are being taken up by the tabView,
//    mayble Ill remove those later ?
    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { dragValue in
                if dragValue.translation.width < 0 { currentDay += Constants.DayTime }
                if dragValue.translation.width > 0 { currentDay -= Constants.DayTime }
            }
    }
    
    private func makeZoomGesture(geo: GeometryProxy) -> some Gesture {
        MagnificationGesture()
            .onChanged { scaleValue in
                dragging = true
                height = min(max(geo.size.height, geo.size.height * 2 * scaleValue), geo.size.height * 4)
            }
            .onEnded { value in dragging = false }
    }
    
    private func filterEvents() -> [RecallCalendarEvent] {
        events.filter { event in
            Calendar.current.isDate(event.startTime, equalTo: currentDay, toGranularity: .day)
        }
    }
    

//    MARK: Body    
    let events: [RecallCalendarEvent]
    
    @State var dragging: Bool = false
    @State var currentDay: Date = .now
    @State var height: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            VStack {
            
                let hoursToDisplay:CGFloat = 24
                let spacing = height / hoursToDisplay
                
                DatesPreview(currentDay: $currentDay)
                
                ScrollViewReader { value in
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            
                            CalendarView(day: currentDay, hoursToDisplay: hoursToDisplay, spacing: spacing)
                            
                            ForEach( filterEvents(), id: \.self ) { component in
                                CalendarEventPreviewView(component: component, spacing: spacing, geo: geo, events: events, dragging: $dragging)
                            }
                            .padding(.leading, 40)
                        }
                        .highPriorityGesture(swipeGesture, including: dragging ? .subviews : .all)
                        .highPriorityGesture(makeZoomGesture(geo: geo), including: dragging ? .subviews : .all)
                        .frame(height: height)
                    }
                    .scrollDisabled(dragging)
                    .onAppear() {
                        let id = Int(Date.now.getHoursFromStartOfDay().rounded(.down) )
                        value.scrollTo( id, anchor: .center )
                        
                        height = geo.size.height * 2
                    }
                }
            }
            .padding(7)
        }
    }
}
