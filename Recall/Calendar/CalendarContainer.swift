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

//MARK: Calendar
struct EmptyCalendarView: View {
    
    private func getCalendarMarkLabel(hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? .now
        
        let includeFormat = hour % 12 == 0
        let format = Date.FormatStyle().hour(.defaultDigits(amPM: includeFormat ? .wide : .omitted))
        return date.formatted(format)
    }
    
    @ViewBuilder
    private func makeCalendarMark(hour: Int, minute: Int = 0, includeLabel: Bool = true, opacity: Double = 0.15) -> some View {
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
                .opacity(opacity)
        }
        .alignmentGuide(VerticalAlignment.top) { _ in
            let timeInterval = Double(hour) *  Constants.HourTime + Double(minute) * Constants.MinuteTime - (Double(startHour) * Constants.HourTime)
            return CGFloat(-(timeInterval) / viewModel.scale)
        }
    }
    
    @ObservedObject private var viewModel = RecallCalendarViewModel.shared
    
    private let startHour: Int
    private let endHour: Int
    
    private let calendarLabelWidth: Double
    private let includeCurrentTimeMark: Bool
    
    init( startHour: Int, endHour: Int, labelWidth: Double, includeCurrentTimeMark: Bool = true ) {
        self.startHour = startHour
        self.endHour = endHour
        self.calendarLabelWidth = labelWidth
        self.includeCurrentTimeMark = includeCurrentTimeMark
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ForEach( startHour...endHour, id: \.self ) { i in
                makeCalendarMark(hour: i)
            }
            
            let currentComps = Calendar.current.dateComponents([.hour, .minute], from: .now)
            
            if includeCurrentTimeMark {
                makeCalendarMark(hour: currentComps.hour!, minute: currentComps.minute!, includeLabel: false, opacity: 1)
                    .foregroundStyle(.red)
            }
        }
    }
    
}


//MARK: CalendarContainer
struct CalendarContainer: View {
    
//    MARK: Initialization
    @ObservedObject private var viewModel = RecallCalendarViewModel.shared
    
    private let events: [RecallCalendarEvent]
    private let summaries: [RecallDailySummary]
    
    private let calendarLabelWidth: Double = 25
    private let scrollDetectionPadding: Double = 200
    
    private let coordinateSpaceName = "CalendarContainerCoordinateSpace"
    
    @State private var showingSummaryView: Bool = false
    
    init(events: [RecallCalendarEvent], summaries: [RecallDailySummary]) {
        self.events = events
        self.summaries = summaries
    }
    
//    MARK: Struct Methods
    private func setCurrentPostIndex(from scrollPosition: CGPoint, in geo: GeometryProxy) {
//        if scrollPosition.x > 0 { return }
        let x = abs(scrollPosition.x)
        
        let daysPerView =  Double(viewModel.daysPerView)
        
        let calendarWidth = abs(geo.size.width - calendarLabelWidth) / daysPerView
        let scrollDetectionPadding = calendarWidth / 2
        
        let proposedIndex = Int(floor( (x + calendarLabelWidth + scrollDetectionPadding) / calendarWidth) )
        let proposedDate = Date.now - (Double(proposedIndex) * Constants.DayTime)
        
        if !viewModel.scrollingCalendar
//            && !self.viewModel.currentDay.matches(proposedDate, to: .day)
        {
            self.viewModel.setCurrentDay(to: proposedDate, scrollToDay: false)
        }
    }
    
    private func setSubDayIndex(from scrollPosition: Double, in geo: GeometryProxy) {
        let proposedIndex: Int = Int(floor((abs(scrollPosition) / geo.size.width) * Double(viewModel.daysPerView)))
        let index = min(max( 0, proposedIndex ), viewModel.daysPerView)
        viewModel.setSubDayIndex(to: index)
    }
    
    private func scrollToCurrentDay(proxy: ScrollViewProxy) {
        let index = floor(Date.now.timeIntervalSince(viewModel.currentDay) / Constants.DayTime)
        withAnimation { proxy.scrollTo(Int(index), anchor: .leading) }
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
    
    private func cleanEvent() {
        if let newEvent {
            if newEvent.title.isEmpty || newEvent.getTagLabel().isEmpty {
                RealmManager.deleteObject(newEvent) { event in
                    newEvent.title.isEmpty
                }
            }
        }
    }
    
    private func createEvent() {
        let subDayOffset = Double(viewModel.subDayIndex) * Constants.DayTime
        
        let startTime = viewModel.getTime(from: newEventoffset, on: viewModel.currentDay) - subDayOffset
        let endTime = startTime + ( newEventResizeOffset * viewModel.scale )
        
        let blankTag = RecallCategory()
        
        let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                        title: "",
                                        notes: "",
                                        urlString: "",
                                        startTime: startTime,
                                        endTime: endTime,
                                        categoryID: blankTag._id,
                                        goalRatings: [:])
        
        self.newEvent = event
        
        RealmManager.addObject(event)
    }
    
    private func createEventHoldGesture(in geo: GeometryProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 1)
            .onEnded { value in withAnimation {
                self.creatingEvent = true
                viewModel.gestureInProgress = true
            } }
            .simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpaceName)) )
            .onChanged { value in
                if !viewModel.gestureInProgress && value.first != nil {
                    
                    self.setSubDayIndex(from: Double(value.second?.location.x ?? 0), in: geo)
                    
                    let position: Double = Double(value.second?.location.y ?? 0)
                    self.newEventoffset = viewModel.roundPosition(position,
                                                                                      to: RecallModel.index.dateSnapping)
                    self.newEventResizeOffset = (Constants.HourTime / 4) / viewModel.scale
                    
                    
                } else if viewModel.gestureInProgress {
                    
                    let position = Double(value.second?.location.y ?? 0)
                    let proposedStartPosition = viewModel.roundPosition(position, to: RecallModel.index.dateSnapping)
                    
                    if proposedStartPosition < newEventoffset {
                        withAnimation { self.newEventoffset = proposedStartPosition }
                        
                    } else {
                        let height = value.second?.location.y ?? 0
                        let proposedResizeOffset = viewModel.roundPosition(height, to: RecallModel.index.dateSnapping) - self.newEventoffset
                        
                        let minLength = (Constants.HourTime / 4) / viewModel.scale
                        withAnimation { self.newEventResizeOffset =  max(minLength, proposedResizeOffset)  }
                    }
                }
            }
            .onEnded { _ in withAnimation {
                if !creatingEvent { return }
                
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
    private func makeEventCreationPreview(on subDayIndex: Int) -> some View {
        if self.creatingEvent && subDayIndex == viewModel.subDayIndex {
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
    
//    MARK: CalendarLabels
    @ViewBuilder
    private func makeCalendarLabels() -> some View {
        let format = Date.FormatStyle().weekday(.abbreviated).day()
        
        HStack(spacing: 0) {
            ForEach(0..<viewModel.daysPerView, id: \.self) { i in
                let day = viewModel.currentDay.addingTimeInterval(Double(i) * -Constants.DayTime)

                let label = day.formatted(format)
                
                HStack {
                    Spacer()
                    UniversalText(label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 7)
        .background()
        .opacity(0.75)
    }
    
//    MARK: CalendarCarousel
    private func calculateSubDayIndex(on day: Date) -> Int {
        let difference = abs(viewModel.currentDay.timeIntervalSince(day))
        let proposedIndex = Int(floor( difference / Constants.DayTime ))
        return proposedIndex % viewModel.daysPerView
    }
    
    @ViewBuilder
    private func makeCalendarCarousel(in geo: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    
                    let dayCount = RecallModel.index.daysSinceFirstEvent()
                    
                    ForEach(0...dayCount, id: \.self) { i in
                        
                        let day = .now.resetToStartOfDay() - (Double(i) * Constants.DayTime)
                        
                        ZStack(alignment: .top) {
                            CalendarView(events: viewModel.getEvents(on: day),
                                             on: day)
                            makeEventCreationPreview(on: calculateSubDayIndex(on: day))
                        }
                        .padding(.horizontal, 2)
                        .frame(width: (geo.size.width - calendarLabelWidth) / Double(viewModel.daysPerView))
                        .task { await viewModel.loadEvents(for: day, in: events) }
                        .id(i)
                    }
                }
                .scrollTargetLayout()
                .onChange(of: viewModel.shouldScrollCalendar) { scrollToCurrentDay(proxy: proxy) }
                
                .background(GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named(coordinateSpaceName)).origin)
                })
                
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in setCurrentPostIndex(from: value, in: geo) }
                .onAppear { scrollToCurrentDay(proxy: proxy) }
                
                .onChange(of: events) { oldValue, newValue in
                    viewModel.invalidateEvents(newEvents: newValue)
                }
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollDisabled(viewModel.gestureInProgress)
            
            
        }
        .padding(.leading, calendarLabelWidth)
    }
    
//    MARK: Body
    var body: some View {
        VStack {
            GeometryReader { geo in
                VStack {
                    ScrollViewReader { proxy in
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            
                            ZStack(alignment: .top) {
                                EmptyCalendarView(startHour: 0, endHour: 26, labelWidth: calendarLabelWidth)
                                
                                makeCalendarCarousel(in: geo)
                                
                                VStack {
                                    Spacer()
                                    
                                    Rectangle()
                                        .frame(height: 10)
                                        .foregroundStyle(.clear)
                                        .allowsHitTesting(false)
                                        .id("scrollTarget")
                                    
                                    Spacer()
                                }
                            }

                            .simultaneousGesture(createEventHoldGesture(in: geo))
                            
                            .coordinateSpace(name: coordinateSpaceName)
                            
                            RecallDailySummaryView(summaries: summaries)
                                .padding(.bottom, 400)
                        }
                        .simultaneousGesture(scaleGesture)
                        .scrollDisabled(viewModel.gestureInProgress)
                        .onAppear { proxy.scrollTo("scrollTarget") }
                        .overlay(alignment: .top) { if viewModel.daysPerView > 1 {
                            makeCalendarLabels()
                                .padding(.leading, calendarLabelWidth)
                        } }
                    }
                }
            }
            .onChange(of: showingEventCreationView) { if !showingEventCreationView { cleanEvent() } }
            .sheet(isPresented: $showingEventCreationView) {
                CalendarEventCreationView.makeEventCreationView(currentDay: viewModel.currentDay,
                                                                editing: true,
                                                                event: newEvent)
            }
            .halfPageScreen("Select Events", presenting: $viewModel.selecting) {
                EventSelectionEditorView()
            }
        }
    }
}
