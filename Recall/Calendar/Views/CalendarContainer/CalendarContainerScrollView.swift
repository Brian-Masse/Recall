//
//  CalendarContainerScrollView.swift
//  Recall
//
//  Created by Brian Masse on 1/22/25.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - CalendarContainerScrollView
struct CalendarContainerScrollView<C: View>: View {
    
    @ObservedObject private var viewModel = RecallCalendarContainerViewModel.shared
    
    private let itemCount: Int
    
    @State private var currentIndex: Int = 0
    @State private var scrollPosition: ScrollPosition = .init(idType: Int.self, edge: .trailing)
    
    private let calendarCycleCount: Int = 5
    @State private var currentCalendarCycle: Int = 0
    
    let contentBuilder: (Int) -> C
    
    init( itemCount: Int, @ViewBuilder contentBuilder: @escaping (Int) -> C ) {
        self.itemCount = itemCount
        self.contentBuilder = contentBuilder
    }
    
//    MARK: convertFromLTrailingIndexSystemToLeading
//    the views, from left to right are indexed 0 to itemCount
//    however, because the calendar is pinned to the right, it makes sense for the right most view to be 0-indexed.
//    the currentIndex uses this trailingAlignment index system.
//    to scroll properly and display the index properly, a TrailingIndexSystem needs to be translated into a leadingIndexSystem
    private func convertBetweenLeadingAndTrailingIndexSystems(from index: Int) -> Int {
        self.itemCount - 1 - index
    }
    
//    MARK: setCurrentIndex
//    any change to the currentIndex should be passed onto the viewModel
//    the id passed into this function should be leadingAligned
    private func setCurrentIndex(to index: Int) {
        if index == self.currentIndex { return }
        
        self.currentIndex = index
        let date = Date.now - Double(currentIndex) * Constants.DayTime
        
        viewModel.setCurrentDay(to: date, scrollToDay: false)
    }
    
//    MARK: ScrollTo
//    This is the function responsible for moving the ScrollView to another view
//    It can be invoked by toggling the shouldScrollCalendar parameter in the viewModel
//    the id passed into this function should be leadingAligned
    private func scrollTo(id: Int, in width: Double, shouldAnimate: Bool = true) {
        setCurrentIndex(to: id)
        let leadingIndex = convertBetweenLeadingAndTrailingIndexSystems(from: id)
        let position = Double(leadingIndex - viewModel.daysPerView + 1) * width / Double(viewModel.daysPerView)
        
        if shouldAnimate { withAnimation {
            scrollPosition.scrollTo( x: position)
        } } else {
            scrollPosition.scrollTo( x: position )
        }
    }
    
//    MARK: getIndexFromCurrentDay
    func getIndexFromCurrentDay() -> Int {
        Int(abs( Date.now.timeIntervalSince( viewModel.currentDay ) ) / Constants.DayTime)
    }
    
    
//    MARK: - makeScrollView
    @ViewBuilder
    private func makeScrollView(in width: Double) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                
                ForEach( 0..<itemCount, id: \.self ) { index in
                    ZStack {
                        Rectangle()
                            .foregroundStyle(.clear)
                        
                        contentBuilder(convertBetweenLeadingAndTrailingIndexSystems(from: index))
                    }
                    .frame(width: width / Double(viewModel.daysPerView))
                }
            }
            .scrollTargetLayout()
        }
        .onAppear { scrollTo(id: currentIndex, in: width, shouldAnimate: false) }
        
        .scrollTargetBehavior(.viewAligned)
        
        .scrollPosition($scrollPosition)
        .defaultScrollAnchor(.trailing)
        
        .scrollDisabled(viewModel.gestureInProgress)
    }
    
//    MARK: - Body
    var body: some View {
        GeometryReader { geo in
            VStack {
                ForEach( 0..<calendarCycleCount, id: \.self ) { i in
                    if i == currentCalendarCycle {
                        makeScrollView(in: geo.size.width)
                    }
                }
            }
            .onChange(of: viewModel.daysPerView) { withAnimation { currentCalendarCycle = (currentCalendarCycle + 1) % calendarCycleCount } }
            
            .onChange(of: viewModel.scrollCalendar) { self.scrollTo(id: getIndexFromCurrentDay(), in: geo.size.width) }
            .onChange(of: scrollPosition) { oldValue, newValue in
                if let id = newValue.viewID(type: Int.self) { setCurrentIndex(to: convertBetweenLeadingAndTrailingIndexSystems(from: id + viewModel.daysPerView - 1 )) }
            }
        }
    }
}

//#Preview {
//    CalendarContainerScrollView()
//}

