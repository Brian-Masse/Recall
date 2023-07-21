//
//  CalendarComponentView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift

//Should only be placed ontop of a caldndar container
struct CalendarEventPreviewView: View {
    
    private let blockCoordinateSpaceKey: String = "blockCOordinateSpace"
    private let holdDuration: Double = 0.1
    
    private enum TimeRounding: Int {
        case hour = 1
        case halfHour = 2
        case querter = 4
    }
    
    private enum ResizeDirection: Int {
        case up = 1
        case down = -1
    }
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedRealmObject var component: RecallCalendarEvent
    
    let spacing: CGFloat
    let geo: GeometryProxy
    
    var overlapData: RecallCalendarEvent.OverlapData { component.getOverlapData(in: geo.size.width - 20) }
    
    @State var startDate: Date = .now
    @State var endDate: Date = .now
    @State var length: CGFloat = 0  //measured in hours
    @State var roundedStartDate: Date = .now
    
    @Binding var dragging: Bool
    @State var moving: Bool = false
    @State var resizing: Bool = false //used to block the movement gesture while resizing
    @State var showingComponent: Bool = false
    
    
//    MARK: Convenience Functions
    
    private func getVerticalOffset(from startDate: Date) -> CGFloat {
        CGFloat(startDate.getHoursFromStartOfDay()) * spacing
    }
    
    private func getHorizontalOffset( ) -> CGFloat {
        overlapData.offset
    }
    
    private func clampPosition(_ pos: CGFloat ) -> CGFloat {
        min( max( 0, pos ), (24 * spacing) - 1 )
    }
    
    private func beginMoving() {
        dragging = true
        moving = true
    }
    
    private func beginResizing() {
        dragging = true
        resizing = true
    }
    
    private func getWidth() -> CGFloat {
        overlapData.width
    }
    
    
//    MARK: Drag
    private var drag: some Gesture {
        DragGesture(coordinateSpace: .named(blockCoordinateSpaceKey))
            .onChanged { dragGesture in
                if !moving || resizing { return }
                startDate = getTime(from: clampPosition(dragGesture.location.y))
                endDate   = startDate + (length * Constants.HourTime)
                
                roundedStartDate = getNearestTime(from: clampPosition(dragGesture.location.y), to: .halfHour)
            }
            .onEnded { dragGesture in
                if dragging && !resizing {
                    dragging = false
                    moving = false
                    component.updateDate(startDate: roundedStartDate, endDate: roundedStartDate + ( length * Constants.HourTime ) )
                }
            }
    }
    
//    MARK: Resize
    private func resizeGesture(_ direction: ResizeDirection) -> some Gesture {
        DragGesture( coordinateSpace: .named(blockCoordinateSpaceKey) )
            .onChanged { dragGesture in
                if !dragging || !resizing { return }
                if direction == .up {
                    startDate        = min(getTime(from: clampPosition(dragGesture.location.y)), endDate - Constants.HourTime)
                    roundedStartDate = min(getNearestTime(from: clampPosition(dragGesture.location.y), to: .halfHour), endDate - Constants.HourTime)
                    length           = endDate.timeIntervalSince(startDate) / Constants.HourTime
                } else {
                    endDate             = max(getTime(from: clampPosition(dragGesture.location.y)), startDate + Constants.HourTime)
                    let roundedEndDate  = max(getNearestTime(from: clampPosition(dragGesture.location.y), to: .halfHour, roundingRule: .up), startDate + Constants.HourTime)
                    length              = endDate.timeIntervalSince(startDate) / Constants.HourTime
                    roundedStartDate    = roundedEndDate - length * Constants.HourTime
                }
            }
            .onEnded { dragGesture in
                dragging = false
                resizing = false
                if direction == .up { component.updateDate(startDate: roundedStartDate)
                } else { component.updateDate(endDate: roundedStartDate + length * Constants.HourTime ) }
            }
    }
    
//    When a user begins dragging or resizing the box that appears to show them where it will be snapped to needs to make sure that its initial position is correct
    private func prepareMovementSnapping() {
        roundedStartDate = startDate
    }
    
//    MARK: Struct Methods
    
    private func getTime(from position: CGFloat) -> Date {
        let hour = (position / spacing).rounded(.down)
        let minutes = ((position / spacing) - hour) * CGFloat(Constants.MinuteTime)
        
        return Calendar.current.date(bySettingHour: Int(hour), minute: Int(minutes), second: 0, of: startDate) ?? .now
    }
    
    private func getNearestTime(from position: CGFloat, to timeRounding: TimeRounding, roundingRule: FloatingPointRoundingRule = .down ) -> Date {
        var hour = (position / spacing).rounded(.down)
        let minutes = ((position / spacing) - hour)
        var roundedMinutes = ((minutes * CGFloat(timeRounding.rawValue)).rounded(roundingRule) / CGFloat(timeRounding.rawValue)) * CGFloat(Constants.MinuteTime)
        
        if roundedMinutes == 60 {
            roundedMinutes = 0
            hour += 1
        }
        
        return Calendar.current.date(bySettingHour: Int(hour), minute: Int(roundedMinutes), second: 0, of: startDate) ?? .now
    }
    
    private func setup() {
        startDate = component.startTime
        endDate = component.endTime
        
        let startTime = component.startTime.getHoursFromStartOfDay()
        let endTime = component.endTime.getHoursFromStartOfDay()
        length = endTime - startTime
    }
    
//    MARK: Body
    @ViewBuilder
    private func makeLengthHandle(_ direction: ResizeDirection) -> some View {
        Rectangle()
            .foregroundColor(.blue)
            .onTapGesture { }
            .onLongPressGesture(minimumDuration: holdDuration) { beginResizing() }
            .simultaneousGesture(resizeGesture( direction ))
            .frame(minHeight: 10, maxHeight: 20)
    }
    
    var body: some View {
        ZStack {
            
            if moving || resizing {
                Rectangle()
                    .foregroundColor(.red.opacity(0.5))
                    .cornerRadius(Constants.UIDefaultCornerRadius)
                    .frame(width: getWidth(), height: CGFloat(length) * spacing)
                    .offset(x: getHorizontalOffset(), y: getVerticalOffset(from: roundedStartDate))
            }
        
            VStack(alignment: .leading) {
                
                HStack {
                    UniversalText( component.title, size: Constants.UISubHeaderTextSize, true )
                    Spacer()
                    UniversalText( "\(component.category?.label ?? "?"), \(component.category?.productivity ?? 0)", size: Constants.UIDefaultTextSize )
                }
                
                Spacer()

                UniversalText( startDate.formatted(date: .omitted, time: .complete), size: Constants.UIDefaultTextSize )
                Spacer()
                UniversalText( endDate.formatted(date: .omitted, time: .complete), size: Constants.UIDefaultTextSize )
                
            }
            .padding()
            .frame(width: getWidth(), height: max(CGFloat(length) * spacing, 20))
            .overlay(VStack {
                makeLengthHandle(.up)
                Spacer()
                makeLengthHandle(.down)
            })
            .background(colorScheme == .light ? .white : Colors.darkGrey )
            .cornerRadius(Constants.UIDefaultCornerRadius)
            .offset(x: getHorizontalOffset(), y: getVerticalOffset(from: startDate))
            
            .onTapGesture { showingComponent = true }
            .onLongPressGesture(minimumDuration: holdDuration ) { beginMoving() }
            .simultaneousGesture( drag, including:  !resizing ? .all : .subviews  )
            
            .coordinateSpace(name: blockCoordinateSpaceKey)
            .onAppear { setup() }
            .onChange(of: dragging) { newValue in prepareMovementSnapping() }
            .shadow(radius: (resizing || moving) ? 10 : 0)
            .sheet(isPresented: $showingComponent) {
                CalendarEventView(component: component,
                                      startDate: component.startTime,
                                      endDate: component.endTime)
            }
        }
        
    }
}


//MARK: Full Screen View
struct CalendarEventView: View {
    
    @Environment( \.presentationMode ) var presentationMode
    
    @ObservedRealmObject var component: RecallCalendarEvent
 
    @State var editing: Bool = false
    
    @State var startDate: Date
    @State var endDate: Date
    
    var body: some View {
        
        VStack(alignment: .leading) {
                
            HStack {
                
                UniversalText( component.title, size: Constants.UITitleTextSize, true )
                Spacer()
                ShortRoundedButton("Dismiss", icon: "chevron.down") { presentationMode.wrappedValue.dismiss() }
                
            }
            
            DatePicker(selection: $startDate, displayedComponents: [.hourAndMinute]) { Text("Start Date") }
            DatePicker(selection: $endDate, displayedComponents: [.hourAndMinute]) { Text("End Date") }
            
            UniversalText( component.category?.label ?? "?", size: Constants.UIDefaultTextSize, true )
            
            ForEach( component.goalRatings ) { node in
                HStack {
                    UniversalText( node.key, size: Constants.UIDefaultTextSize, true )
                    Spacer()
                    UniversalText( node.data, size: Constants.UIDefaultTextSize )
                }
            }
            
            Spacer()
            
            RoundedButton(label: "Done", icon: "checkmark.seal") {
                component.update(title: component.title, startDate: startDate, endDate: endDate)
            }
            
        }
        .padding()
        .universalBackground()
    }
}
