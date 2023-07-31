//
//  CalendarContinerView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI

struct CalendarContainer: View {
    
//    MARK: CalendarView
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
                .offset(y: CGFloat(hour - CGFloat(startHour)) * spacing )
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
        let spacing: CGFloat
        
        let startHour: Int
        let endHour: Int
        
        var body: some View {
            ZStack(alignment: .top) {
                ForEach(startHour..<endHour, id: \.self) { hr in
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
        DragGesture(minimumDistance: 30)
            .onChanged{ dragValue in
//                print("dragging")
            }
            .onEnded { dragValue in

                if dragValue.translation.width < 0 { slideDirection = .right }
                if dragValue.translation.width > 0 { slideDirection = .left }
                
                withAnimation(.easeInOut(duration: 0.25)) {
                    if dragValue.translation.width < 0 { currentDay += Constants.DayTime }
                    if dragValue.translation.width > 0 { currentDay -= Constants.DayTime }
                }
                
            }
    }
    
    private func makeZoomGesture(geo: GeometryProxy) -> some Gesture {
        MagnificationGesture()
            .onChanged { scaleValue in
                dragging = true
//                height = min(max(geo.size.height, geo.size.height * 2 * scaleValue), geo.size.height * 4)
            }
            .onEnded { value in dragging = false }
    }
    
    private func filterEvents() -> [RecallCalendarEvent] {
        events.filter { event in
            Calendar.current.isDate(event.startTime, equalTo: currentDay, toGranularity: .day)
        }
    }
    

//    MARK: Body
    
    let geo: GeometryProxy
    let scale: CGFloat
    let events: [RecallCalendarEvent]
    
    let startHour: Int
    let endHour: Int
    
    let background: Bool
    
    private var height: CGFloat { geo.size.height * scale }
    
    @State var dragging: Bool = false
    @Binding var currentDay: Date
    @Binding var slideDirection: AnyTransition.SlideDirection
    
    @Namespace private var animation
    
    init( at currentDay: Binding<Date>, with events: [RecallCalendarEvent], from startHour: Int, to endHour: Int, geo: GeometryProxy, scale: CGFloat = 2, swipeDirection: Binding<AnyTransition.SlideDirection> = Binding { .right } set: { _, _ in }, background: Bool = false ) {
        self.events = events
        self.startHour = startHour
        self.endHour = endHour
        self.geo = geo
        self.scale = scale
        self.background = background
        self._currentDay = currentDay
        self._slideDirection = swipeDirection
    }
    
    var body: some View {
        VStack {
        
            let spacing = height / CGFloat( endHour - startHour )
            
            ScrollViewReader { value in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        
                        CalendarView(day: currentDay, spacing: spacing, startHour: startHour, endHour: endHour)
                        
                        Group {
                            ForEach( filterEvents(), id: \.self ) { event in
                                CalendarEventPreviewView(event: event,
                                                         spacing: spacing,
                                                         geo: geo,
                                                         startHour: startHour,
                                                         events: events,
                                                         dragging: $dragging)
                            }
                            .padding(.leading, 40)
                        }
                        .if( slideDirection == .right ) { view in view.transition(AnyTransition.slideAwayTransition(.right)) }
                        .if( slideDirection == .left ) { view in view.transition(AnyTransition.slideAwayTransition(.left)) }
                    }
                    .frame(height: height)
                }
                .scrollDisabled(dragging)
                .onAppear() {
                    let id = Int(Date.now.getHoursFromStartOfDay().rounded(.down) )
                    value.scrollTo( id, anchor: .center )
                }
                .if(background) { view in
                    view.opaqueRectangularBackground()
                }
            }
            .onTapGesture { }
            .highPriorityGesture(swipeGesture, including: dragging ? .subviews : .all)
        }
    }
}
