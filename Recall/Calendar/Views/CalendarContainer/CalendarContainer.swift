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
    
//    MARK: Vars
    private var viewModel = RecallCalendarContainerViewModel.shared
    
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
    
//    MARK: Vars
    @ObservedObject private var viewModel = RecallCalendarContainerViewModel.shared
    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
    private let events: [RecallCalendarEvent]
    private let summaries: [RecallDailySummary]
    
    private let calendarLabelWidth: Double = 25
    private let scrollDetectionPadding: Double = 200
    
    private let coordinateSpaceName = "CalendarContainerCoordinateSpace"
    
    @State private var showingSummaryView: Bool = false
    
    @State private var scrolledToEvents: Bool = false
    
    init(events: [RecallCalendarEvent], summaries: [RecallDailySummary]) {
        self.events = events
        self.summaries = summaries
    }
    
    @State private var previousScrollOffset: Double = 0
    
//    MARK: Struct Methods
    private func setCurrentPostIndex(from scrollPosition: CGPoint, in geo: GeometryProxy, dayCount: Int) {

        if viewModel.scrollingCalendar { return }
        if !viewModel.initialCalendarWidthSet { viewModel.setInitialWidth(abs(scrollPosition.x)) }
        
        let x = viewModel.initialCalendarWidth - abs(scrollPosition.x)
        
//        set both the baseOffset and baseIndex for the calendarContainer
//        this has is so that when the user changes a preview size, the offset and index are "zero'd", and the scorlling happens properly
        if viewModel.initialDaysPerView != viewModel.daysPerView {
            viewModel.setBaseCalendarOffset(to: x)
            viewModel.initialDaysPerView = viewModel.daysPerView
        }
        
        let daysPerView = Double(viewModel.daysPerView)
        
        let calendarWidth = (geo.size.width - calendarLabelWidth) / daysPerView
        
        let scrollDetectionPadding = calendarWidth / 2
        let proposedIndex = Int(floor( (x - viewModel.baseCalendarOffset + scrollDetectionPadding) / calendarWidth) ) + viewModel.baseCalendarIndex
        let proposedDate = Date.now - (Double(proposedIndex) * Constants.DayTime)

        if proposedDate.matches(viewModel.currentDay, to: .day) { return }
        self.viewModel.setCurrentDay(to: proposedDate, scrollToDay: false)
        
    }
    
    private func setSubDayIndex(from scrollPosition: Double, in geo: GeometryProxy) {
        let proposedIndex: Int = Int(floor((abs(scrollPosition) / geo.size.width) * Double(viewModel.daysPerView)))
        let index = min(max( 0, proposedIndex ), viewModel.daysPerView)
        viewModel.setSubDayIndex(to: index)
    }
    
//    MARK: ScrollToCurrentDay
    private func scrollToCurrentDay(proxy: ScrollViewProxy) {
        let dayCount = RecallModel.index.daysSinceFirstEvent()
        let index = floor(Date.now.timeIntervalSince(viewModel.currentDay) / Constants.DayTime)
        withAnimation { proxy.scrollTo(dayCount - Int(index), anchor: .leading) }
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
    
    @State private var newEventoffset: Double = 0
    @State private var newEventResizeOffset: Double = 0
    
    private func cleanEvent() {
        if let newEvent {
            if newEvent.isInvalidated { return }
            if newEvent.title.isEmpty || newEvent.getTagLabel().isEmpty {
                RealmManager.deleteObject(newEvent) { event in
                    newEvent.title.isEmpty
                }
            }
        }
    }
    
    private func createEvent() {
        let subDayOffset = Double(1 - viewModel.subDayIndex) * Constants.DayTime
        
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
                if viewModel.gestureInProgress { return }
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
                
                cleanEvent()
                
                creatingEvent = false
                viewModel.gestureInProgress = false
                
                if self.newEventResizeOffset != 0 {
                    self.createEvent()
                    coordinator.presentSheet(.eventEdittingView(event: newEvent!))
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
        let format = Date.FormatStyle().weekday(.abbreviated).month().day()
        
        HStack(spacing: 0) {
            ForEach(0..<viewModel.daysPerView, id: \.self) { i in
                let day = viewModel.currentDay.addingTimeInterval(Double( -viewModel.daysPerView + i + 1) * Constants.DayTime)

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
        let dayCount = RecallModel.index.daysSinceFirstEvent()
        
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    
                    ForEach(0...dayCount, id: \.self) { i in
                        
                        let day = Date.now.resetToStartOfDay() + Double(i - dayCount) * Constants.DayTime
                        
                        ZStack(alignment: .top) {
                            CalendarView(events: viewModel.getEvents(on: day), on: day)
                            
                            makeEventCreationPreview(on: 1 - calculateSubDayIndex(on: day))
                        }
                        .padding(.horizontal, 2)
                        .frame(width: (geo.size.width - calendarLabelWidth) / Double(viewModel.daysPerView))
                        .task { await viewModel.loadEvents(for: day, in: events) }
                    }
                }
                .scrollTargetLayout()
                .onChange(of: viewModel.shouldScrollCalendar) { scrollToCurrentDay(proxy: proxy) }
                
                .background(GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named(coordinateSpaceName)).origin)
                })
                
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in setCurrentPostIndex(from: value, in: geo, dayCount: dayCount) }
            }
            .defaultScrollAnchor(.trailing)
            .scrollTargetBehavior(.viewAligned)
            .scrollDisabled(viewModel.gestureInProgress)
            
            
        }
        .padding(.leading, calendarLabelWidth)
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                
                ScrollView(.vertical, showsIndicators: false) {
                    
                    ZStack(alignment: .top) {
                        EmptyCalendarView(startHour: 0, endHour: 26, labelWidth: calendarLabelWidth)
                        
                        makeCalendarCarousel(in: geo)
                        
                        VStack {
                            Rectangle()
                                .frame(height: (9 * Constants.HourTime) / viewModel.scale)
                            
                            Rectangle()
                                .id("scrollTarget")
                        }
                        .allowsHitTesting(false)
                        .foregroundStyle(.clear)
                    }
                    .simultaneousGesture(createEventHoldGesture(in: geo))
                    .onTapGesture { viewModel.gestureInProgress = false }
                    
                    .coordinateSpace(name: coordinateSpaceName)
                    .padding(.top, 30)
                    
                    RecallDailySummaryView(summaries: summaries)
                        .padding(.bottom, 400)
                }
                .simultaneousGesture(scaleGesture)
                .scrollDisabled(viewModel.gestureInProgress)
                .onAppear { if !scrolledToEvents {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("scrollTarget", anchor: .top) }
                        scrolledToEvents = true
                } }
//                .onChange(of: events) { oldValue, newValue in
//                    viewModel.invalidateEvents(events: newValue)
//                }
                .overlay(alignment: .top) { if viewModel.daysPerView > 1 {
                    makeCalendarLabels()
                        .padding(.leading, calendarLabelWidth)
                } }
            }
        }
    }
}
