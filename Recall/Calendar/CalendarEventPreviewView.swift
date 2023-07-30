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
    let startHour: Int
    let events: [RecallCalendarEvent]
    
    var overlapData: RecallCalendarEvent.OverlapData { component.getOverlapData(in: geo.size.width - 20, from: events) }
    
    @State var startDate: Date = .now
    @State var endDate: Date = .now
    @State var length: CGFloat = 0  //measured in hours
    @State var roundedStartDate: Date = .now
    
    @Binding var dragging: Bool
    @State var moving: Bool = false
    @State var resizing: Bool = false //used to block the movement gesture while resizing
    
    @State var showingComponent: Bool = false
    @State var showingEditingView: Bool = false
    
    
    
//    MARK: Convenience Functions
    
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
        max(overlapData.width, 1)
    }
    
    private func getHeight() -> CGFloat {
        max(CGFloat(length) * spacing, 20)
    }
    
    private func getVerticalOffset(from startDate: Date) -> CGFloat {
        max(CGFloat(startDate.getHoursFromStartOfDay() - Double(startHour)) * spacing, 0)
    }
    
    private func getHorizontalOffset( ) -> CGFloat {
        overlapData.offset
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
        let pos = position + ( CGFloat(startHour) * spacing )
        let hour = (pos / spacing).rounded(.down) + CGFloat(startHour)
        let minutes = ((pos / spacing) - hour) * CGFloat(Constants.MinuteTime)
        
        return Calendar.current.date(bySettingHour: Int(hour), minute: Int(minutes), second: 0, of: startDate) ?? .now
    }
    
    private func getNearestTime(from position: CGFloat, to timeRounding: TimeRounding, roundingRule: FloatingPointRoundingRule = .down ) -> Date {
        let pos = position + ( CGFloat(startHour) * spacing )
        var hour = (pos / spacing).rounded(.down)
        let minutes = ((pos / spacing) - hour)
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
        if resizing {
            Rectangle()
                .foregroundColor(.white.opacity(0.01))
                .onTapGesture { }
                .simultaneousGesture(resizeGesture( direction ))
                .frame(minHeight: 10, maxHeight: 20)
                .overlay(
                    Image(systemName: direction == .up ? "chevron.up" : "chevron.down")
                        .padding()
                        .padding(.horizontal)
                        .foregroundColor(.black)
                        .rectangularBackgorund()
                        .offset(y: direction == .up ? 20 : -20)
                        .onTapGesture { }
                        .simultaneousGesture(resizeGesture( direction ))
                )
        }
    }
    
    var body: some View {
        ZStack {
            if moving || resizing {
                Rectangle()
                    .foregroundColor(.red.opacity(0.5))
                    .cornerRadius(Constants.UIDefaultCornerRadius)
                    .frame(width: getWidth(), height: getHeight())
                    .offset(x: getHorizontalOffset(), y: getVerticalOffset(from: roundedStartDate))
            }
        
            CalendarEventPreviewContentView(event: component, width: getWidth(), height: length)
                .frame(width: getWidth(), height: getHeight())
                .overlay(VStack {
                    makeLengthHandle(.up)
                    Spacer()
                    makeLengthHandle(.down)
                })
                .contextMenu {
                    Button { beginMoving()  }  label: { Label("move", systemImage: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left") }
                    Button {beginResizing() } label: { Label("resize", systemImage: "rectangle.expand.vertical") }
                    Button {showingEditingView = true } label: { Label("edit", systemImage: "slider.horizontal.below.rectangle") }
                    Button(role: .destructive) { component.delete() } label: { Label("delete", systemImage: "trash") }
                }
                .offset(x: getHorizontalOffset(), y: getVerticalOffset(from: startDate))
                
                .onTapGesture { showingComponent = true }
                .simultaneousGesture( drag, including:  !resizing ? .all : .subviews  )
                .coordinateSpace(name: blockCoordinateSpaceKey)
            
                .onAppear { setup() }
                .onChange(of: dragging) { newValue in prepareMovementSnapping() }
                .shadow(radius: (resizing || moving) ? 10 : 0)
                .sheet(isPresented: $showingComponent) {
                    CalendarEventView(event: component, events: events)
                }
        }
        
    }
}
