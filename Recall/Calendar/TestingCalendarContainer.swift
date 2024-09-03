//
//  TestingCalendarContainer.swift
//  Recall
//
//  Created by Brian Masse on 8/21/24.
//

import Foundation
import SwiftUI
import UIUniversals

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

struct TestingCalendarContainer: View {
    
//    MARK: Calendar
    private func getCalendarMarkLabel(hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? .now
        
        let includeFormat = hour % 12 == 0
        let format = Date.FormatStyle().hour(.defaultDigits(amPM: includeFormat ? .wide : .omitted))
        return date.formatted(format)
    }
    
    @ViewBuilder
    private func makeCalendarMark(hour: Int, minute: Int = 0, includeLabel: Bool = true) -> some View {
        HStack(alignment: .top) {
            
            if includeLabel {
                UniversalText( getCalendarMarkLabel(hour: hour),
                               size: Constants.UISmallTextSize,
                               font: Constants.mainFont  )
                    .lineLimit(1)
                    .frame(width: calendarLabelWidth, alignment: .trailing)
            }
            
            Rectangle()
                .frame(height: 0.5)
                .opacity(0.4)
        }
        .alignmentGuide(VerticalAlignment.top) { _ in
            let timeInterval = Double(hour) *  Constants.HourTime + Double(minute) * Constants.MinuteTime
            return CGFloat(-(timeInterval) / viewModel.scale)
        }
    }
    
    @ViewBuilder
    private func makeCalendar() -> some View {
        ZStack(alignment: .top) {
            ForEach( 0...30, id: \.self ) { i in
                makeCalendarMark(hour: i)
            }
            
            let currentComps = Calendar.current.dateComponents([.hour, .minute], from: .now)
            
            makeCalendarMark(hour: currentComps.hour!, minute: currentComps.minute!, includeLabel: false)
                .foregroundStyle(.red)
        }
    }
    
//    MARK: Initialization
    @ObservedObject private var viewModel = RecallCalendarViewModel.shared
    
    private let events: [RecallCalendarEvent]
    
    private let calendarLabelWidth: Double = 20
    private let scrollDetectionPadding: Double = 200
    
    private let coordinateSpaceName = "CalendarContainerCoordinateSpace"
    
    init(events: [RecallCalendarEvent]) {
        self.events = events
    }
    
//    MARK: Struct Methods
    private func setCurrentPostIndex(from scrollPosition: CGPoint, in geo: GeometryProxy) {
        if scrollPosition.x > 0 { return }
        let proposedIndex = Int(floor(abs(scrollPosition.x - calendarLabelWidth - scrollDetectionPadding) / abs(geo.size.width - calendarLabelWidth)))
        let proposedDate = Date.now - (Double(proposedIndex) * Constants.DayTime)
        
        if !self.viewModel.currentDay.matches(proposedDate, to: .day) {
            self.viewModel.setCurrentDay(to: proposedDate, scrollToDay: false)
        }
    }
    
    private func scrollToCurrentDay(proxy: ScrollViewProxy) {
        let index = floor(Date.now.timeIntervalSince(viewModel.currentDay) / Constants.DayTime)
        withAnimation { proxy.scrollTo(Int(index)) }
    }
    
//    MARK: ScaleGesture
    @State private var lastScale: Double = 100
    
    private var scaleGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let proposedScale = lastScale * (1 / value.magnification)
                let difference = proposedScale - lastScale
                let scale = lastScale + (difference / 2)
                
                self.viewModel.setScale(to: scale)
            }
            .onEnded { value in
                self.lastScale = viewModel.scale
            }
    }
    
//    MARK: EventCreationGesture
    @State private var newEvent: RecallCalendarEvent? = nil
    @State private var creatingEvent: Bool = false
    @State private var showingEventCreationView: Bool = false
    
    @State private var newEventoffset: Double = 0
    @State private var newEventResizeOffset: Double = 0
    
    private func createEvent() {
        let startTime = CalendarEventPreviewView.getTime(from: newEventoffset, on: viewModel.currentDay)
        let endTime = startTime + ( newEventResizeOffset * viewModel.scale )
        
        let blankTag = RecallCategory()
        
        let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                        title: "",
                                        notes: "",
                                        startTime: startTime,
                                        endTime: endTime,
                                        categoryID: blankTag._id,
                                        goalRatings: [:])
        
        self.newEvent = event
        
        RealmManager.addObject(event)
    }
    
    private var createEventHoldGesture: some Gesture {
        LongPressGesture(minimumDuration: 1)
            .onEnded { value in withAnimation {
                
                print("creating")
                self.creatingEvent = true
                viewModel.gestureInProgress = true
            } }
            .simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpaceName)) )
            .onChanged { value in
                if !viewModel.gestureInProgress && value.first != nil {
                    print("initial sizing")
                    
                    let position: Double = Double(value.second?.location.y ?? 0)
                    self.newEventoffset = CalendarEventPreviewView.roundPosition(position,
                                                                                      to: RecallModel.index.dateSnapping)
                    self.newEventResizeOffset = Constants.HourTime / viewModel.scale
                    
                } else if viewModel.gestureInProgress {
                    
                    let height = value.second?.translation.height ?? 0
                    let proposedResizeOffset = CalendarEventPreviewView.roundPosition(height,
                                                                                      to: RecallModel.index.dateSnapping)
                    
                    withAnimation { self.newEventResizeOffset =  max(0, proposedResizeOffset) }
                }
            }
            .onEnded { _ in withAnimation {
                print("done ")
                
                creatingEvent = false
                viewModel.gestureInProgress = false
                
                if self.newEventResizeOffset != 0 {
                    self.createEvent()
                    self.showingEventCreationView = true
                }
            } }
    }
    
//    MARK: EventCreationPreview
    @ViewBuilder
    private func makeEventCreationPreview() -> some View {
        if self.creatingEvent {
            ZStack {
                RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                    .stroke(style: .init(lineWidth: 3, lineCap: .round, dash: [5, 10], dashPhase: 15))
                RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                    .opacity(0.3)
            }
            .opacity(0.3)
            .allowsHitTesting(false)
            .offset(y: newEventoffset)
            .frame(height: newEventResizeOffset)
        }
    }
    
//    MARK: CalendarCarousel
    @ViewBuilder
    private func makeCalendarCarousel(in geo: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    
                    ForEach(0...100, id: \.self) { i in
                        
                        let day = .now - (Double(i) * Constants.DayTime)
                        
                        ZStack(alignment: .top) {
                            TestCalendarView(events: viewModel.getEvents(on: day),
                                             on: day)
                            
                            makeEventCreationPreview()
                        }

                        .padding(.horizontal, 5)
                        .frame(width: geo.size.width - calendarLabelWidth)
                        .id(i)
                        .task { await viewModel.loadEvents(for: day, in: events) }
                    }
                    .scrollTargetLayout()
                }
                .background(GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named(coordinateSpaceName)).origin)
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in setCurrentPostIndex(from: value, in: geo) }
                .onAppear { scrollToCurrentDay(proxy: proxy) }
                .onChange(of: viewModel.shouldScrollCalendar) { _ in scrollToCurrentDay(proxy: proxy) }
                .onChange(of: events) { oldValue, newValue in
                    viewModel.invalidateEvents(newEvents: newValue)
                }
            }
            .scrollTargetBehavior(.paging)
            
        }
        .padding(.leading, calendarLabelWidth)
    }
    
//    MARK: Body
    var body: some View {
        VStack {
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        
                        ZStack(alignment: .top) {
                            makeCalendar()
                            
                            makeCalendarCarousel(in: geo)
                        }
                        .padding(.bottom, 150)
                        
                        .onTapGesture { }
                        .gesture(createEventHoldGesture)
                        
                        .coordinateSpace(name: coordinateSpaceName)
                    }
//                    .highPriorityGesture(scaleGesture)
                    .scrollDisabled(viewModel.gestureInProgress)
                }
            }
            .sheet(isPresented: $showingEventCreationView) {
                CalendarEventCreationView.makeEventCreationView(currentDay: viewModel.currentDay,
                                                                editing: true,
                                                                event: newEvent)
            }
        }
    }
}

#Preview {
    TestingCalendarContainer(events: [])
}
