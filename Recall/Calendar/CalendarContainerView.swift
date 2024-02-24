//
//  CalendarContinerView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI
import UIUniversals

class CalendarContainerModel: ObservableObject {
    
    
    
    
}


struct CalendarContainer: View {
    
//    MARK: CalendarView
    private struct CalendarView: View {
        
        @ViewBuilder
        func makeTimeMarker(hour: CGFloat, label: String, color: Color) -> some View {
            VStack {
                HStack(alignment: .top) {
                    UniversalText( label, size: Constants.UISmallTextSize, font: Constants.mainFont  )
                    
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
    
//    MARK: Convenience Functions
    private func getTime(from pressLocation: CGFloat) -> Date {
        let position = pressLocation - scrollPosition.y
        
        let hour = (position / spacing).rounded(.down) + CGFloat(startHour)
        let minutes = ((position / spacing) - hour) * CGFloat(Constants.MinuteTime)
        
        print(hour, minutes)
        
        let date = Calendar.current.date(bySettingHour: Int(hour), minute: Int(minutes), second: 0, of: .now) ?? .now
        
        return date.round(to: .halfHour)
    }
    
    private func getPosition(from time: Date) -> CGFloat {
        let hours = time.getHoursFromStartOfDay()
        
        return hours * spacing
    }

//    MARK: Gestures
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 100)
            .onEnded { dragValue in

                if dragValue.translation.width < 0 { slideDirection = .right }
                if dragValue.translation.width > 0 { slideDirection = .left }
                
                withAnimation(.easeInOut(duration: 0.25)) {
                    if dragValue.translation.width < 0 { currentDay += Constants.DayTime }
                    if dragValue.translation.width > 0 { currentDay -= Constants.DayTime }
                }
                
            }
    }
    
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .onEnded { value in dragging = true }
    }
    
    @MainActor
    private var creationGesture: some Gesture {
        DragGesture(minimumDistance: 40)
            .onChanged { value in
                if dragging {
                        
                    
//                    This sets the start time to the first position of the drag gesture
//                    and then doesnt update it until the gesture is over
                    if !self.creatingEvent{
                        
                        let startTime = getTime(from: value.location.y)
                        let endTime = startTime + ( RecallModel.index.defaultEventLength )
                        
                        let blankTag = RecallCategory()
                        
                        let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                                        title: "New Event",
                                                        notes: "",
                                                        startTime: startTime,
                                                        endTime: endTime,
                                                        categoryID: blankTag._id,
                                                        goalRatings: Dictionary())
                        
                        RealmManager.addObject(event)
                        
                        
                        self.createdEvent = event
                        self.creatingEvent = true
                        
                    } else {
                        
                        let minEndTime = createdEvent.startTime + RecallModel.index.defaultEventLength
                        
                        let endTime = min( getTime(from: value.location.y), minEndTime)
                        
                        createdEvent.updateDate(endDate: endTime)
                        
                    }
                    
                    
                    
                    
                    
//                    self.endTime = getTime(from: value.location.y)
                    
                }
                
            }
            .onEnded { value in
                creatingEvent = false
                dragging = false
            }
    }
    
    private func tapGesture() {
        if selecting { withAnimation { selecting = false }}
        dragging = false
    }
    
    private func filterEvents() -> [RecallCalendarEvent] {
        events.filter { event in
            event.startTime.matches(currentDay, to: .day) &&
            event.startTime.matches(currentDay, to: .month) &&
            event.startTime.matches(currentDay, to: .year)
            
        }
    }
    

//    MARK: vars
    let geo: GeometryProxy
    let scale: CGFloat
    let events: [RecallCalendarEvent]
    
    let startHour: Int
    let endHour: Int
    let background: Bool
    
    var spacing: CGFloat { height / CGFloat( endHour - startHour ) }
    
    @Binding var currentDay: Date
    
    @State var scrollPosition: CGPoint = .zero
    @State var creatingEvent: Bool = false
    @State var dragging: Bool = false
    
    @Binding var slideDirection: AnyTransition.SlideDirection

//    used for selecting events
    @State var selecting: Bool = false
    @State var selection: [ RecallCalendarEvent ] = []
    
    @State var createdEvent: RecallCalendarEvent!
    
    private var height: CGFloat {
        if overrideHeight == nil { return geo.size.height * scale }
        else { return overrideHeight! }
    }
    let overrideHeight: CGFloat?

    init( at currentDay: Binding<Date>, with events: [RecallCalendarEvent], from startHour: Int, to endHour: Int, geo: GeometryProxy, scale: CGFloat = 2, slideDirection: Binding<AnyTransition.SlideDirection> = Binding { .right } set: { _, _ in }, background: Bool = false, overrideHeight: CGFloat? = nil ) {
        self.events = events
        self.startHour = startHour
        self.endHour = endHour
        self.geo = geo
        self.scale = scale
        self.background = background
        self.overrideHeight = overrideHeight
        self._currentDay = currentDay
        self._slideDirection = slideDirection
    }
    
    
//    MARK: Body
    var body: some View {
        VStack {
            
            LongPressGestureView()
            
            ScrollReader($scrollPosition, showingIndicator: false) {
                
                ZStack(alignment: .topLeading) {

                    CalendarView(day: currentDay, spacing: spacing, startHour: startHour, endHour: endHour)
                    
                    Group {
                        let filtered = filterEvents()
                        
                        ForEach( filtered, id: \.self ) { event in
                            CalendarEventPreviewView(event: event,
                                                     spacing: spacing,
                                                     geo: geo,
                                                     startHour: startHour,
                                                     events: filtered,
                                                     dragging: $dragging,
                                                     selecting: $selecting,
                                                     selection: $selection)
                            
                        }
                        .padding(.leading, 40)
                    }
                    .if( slideDirection == .right ) { view in view.transition(AnyTransition.slideAwayTransition(.right)) }
                    .if( slideDirection == .left ) { view in view.transition(AnyTransition.slideAwayTransition(.left)) }
                    
                    Rectangle()
                        .foregroundColor(.white)
                        .opacity( dragging ? 0.01 : 0 )
                        .onTapGesture {
                            dragging = false
                            selecting = false
                        }
                        .zIndex( 1 )
                    
                    //
                    //
                }
                .frame(height: height)
                .padding(.bottom, Constants.UIBottomOfPagePadding)
            }
            .scrollDisabled(dragging || background)
            .if(background) { view in
                view.rectangularBackground(7, style: .primary, stroke: true)
            }

            .onTapGesture { tapGesture() }
            .gesture(longPressGesture)
            
            .simultaneousGesture( creationGesture )
            
            ////            .gesture(creationGesture)
            //
            //            .highPriorityGesture( creationGesture )
            //
            ////            .simultaneousGesture(swipeGesture, including: dragging ? .subviews : .all)
            //            .simultaneousGesture(longPressGesture, including: dragging ? .subviews : .all)
            ////            .gesture(creationGesture, including: dragging ? .subviews : .all)
            //
            //
            ////            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 5) {
            ////                print("oh yeah")
            ////                dragging = true
            //            }
        }
    }
}


struct LongPressGestureView: View {
    @GestureState private var isDetectingLongPress = false
    @State private var completedLongPress = false


    var longPress: some Gesture {
        LongPressGesture(minimumDuration: 3)
            .updating($isDetectingLongPress) { currentState, gestureState,
                    transaction in
                gestureState = currentState
                transaction.animation = Animation.easeIn(duration: 2.0)
            }
            .onEnded { finished in
                self.completedLongPress = finished
            }
    }


    var body: some View {
        Circle()
            .fill(self.isDetectingLongPress ?
                Color.red :
                (self.completedLongPress ? Color.green : Color.blue))
            .frame(width: 100, height: 100, alignment: .center)
            .gesture(longPress)
    }
}
