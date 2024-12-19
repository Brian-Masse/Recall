//
//  RecallUniversals.swift
//  Recall
//
//  Created by Brian Masse on 12/19/24.
//

import Foundation
import SwiftUI
import UIUniversals

//    MARK: - sectionHeader
@ViewBuilder
func makeSectionHeader(
    _ icon: String,
    title: String,
    fillerMessage: String = "",
    isActive: Bool = true,
    fillerAction: (() -> Void)? = nil
) -> some View {
    if isActive {
        HStack {
            RecallIcon(icon)
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            Spacer()
        }
        .padding(.leading)
        .opacity(0.75)
    } else {
        makeSectionFiller(icon: icon, message: fillerMessage, action: fillerAction)
    }
}


//    MARK: makeSectionFiller
@ViewBuilder
private func makeSectionFiller(icon: String, message: String, action: (() -> Void)?) -> some View {
    UniversalButton {
        VStack {
            HStack { Spacer() }
            
            RecallIcon( icon )
                .padding(.bottom, 5)
            
            UniversalText( message, size: Constants.UIDefaultTextSize, font: Constants.mainFont, textAlignment: .center )
                .opacity(0.75)
        }
        .opacity(0.75)
        .rectangularBackground(style: .secondary)
        
    } action: { if let action { action() }}
}

// MARK: - MetaDataLabel
@ViewBuilder
func makeMetaDataLabel(icon: String, title: String, action: (() -> Void)? = nil) -> some View {
    UniversalButton {
        VStack {
            HStack { Spacer() }
            
            RecallIcon(icon)
            
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
        }
        .frame(height: 30)
        .opacity(0.65)
        .rectangularBackground(style: .secondary)
    } action: {
        if let action { action() }
    }
}


//MARK: - YearCalendar
struct YearCalendar: View {
    let maxSaturation: Double
    let color: Color?
    let getValue: (Date) -> Double
    
    init(maxSaturation: Double, color: Color? = nil, forPreview: Bool = false, getValue: @escaping (Date) -> Double) {
        self.maxSaturation = maxSaturation
        self.color = color
        self.getValue = getValue
        self.forPreview = forPreview
        self.width = forPreview ? 12 : 15
    }
    
    private let forPreview: Bool
    private let numberOfDays: Int = 365
    private let width: Double
    
//    MARK: YearCalendarDayView
    private struct DayView: View {
        
        @Environment(\.dismiss) var dismiss
        @Environment(\.colorScheme) var colorScheme
        @ObservedObject private var calendarViewModel = RecallCalendarContainerViewModel.shared
        @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
        
        let startDate: Date
        let index: Int
        
        let width: Double
        let maxSaturation: Double
        let color: Color?
        let forPreview: Bool
        
        let getValue: (Date) -> Double
        
        @State private var saturation: Double = 0
        
        private func loadSaturation() async {
            let date = startDate + Constants.DayTime * Double(index)
            let value = getValue(date)
            
            withAnimation { self.saturation = value }
        }
        
        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .frame(width: width, height: width)
                .foregroundStyle(color == nil ? Colors.getAccent(from: colorScheme) : color!)
                .opacity(saturation / maxSaturation)
                .task { await loadSaturation() }
                .onChange(of: maxSaturation) { Task { await loadSaturation() } }
                .if( !forPreview ) { view in
                    view.onTapGesture {
                        calendarViewModel.setCurrentDay(to: startDate + Constants.DayTime * Double(index))
                        dismiss()
                        coordinator.goTo(.calendar)
                    }
                }
        }
    }
    
//    MARK: YearCalendarMonthLabel
    private struct MonthLabel: View {
        let startDate: Date
        let index: Int
        let width: Double
        
        @State private var isFirstMonthWeek: Bool = false
        @State private var monthDate: Date = .now
        
        private func loadIsFirstMonthWeek() async {
            let date = startDate + Constants.DayTime * Double(index) + 7
            let day = Calendar.current.component(.day, from: date)
            
            withAnimation {
                self.isFirstMonthWeek = (day >= 1 && day < 8)
                self.monthDate = date
            }
        }
        
        private var monthLabel: String {
            let formatter = Date.FormatStyle().month(.abbreviated)
            return monthDate.formatted(formatter)
        }
        
        var body: some View {
            Rectangle()
                .frame(width: width, height: width)
                .foregroundStyle(.clear)
                .overlay(alignment: .leading) { if isFirstMonthWeek {
                    UniversalText( monthLabel, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                        .frame(width: 50, alignment: .leading)
                } }
                .task { await loadIsFirstMonthWeek() }
        }
    }
    
//    MARK: YearCalendarBody
    var body: some View {
        
        let startDate = Date.now.resetToStartOfDay() - (Constants.DayTime * Double(numberOfDays))
        let startDateOffset = Calendar.current.component(.weekday, from: startDate) - 1
        let colCount = ceil(Double(numberOfDays + startDateOffset) / 7)
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 3) {
                ForEach(0..<Int(colCount), id: \.self) { col in
                    
                    LazyVStack(alignment: .leading, spacing: 3) {
                        
                        if !forPreview {
                            MonthLabel(startDate: startDate, index: (col * 7) - startDateOffset, width: width)
                        }
                        
                        ForEach(0..<7, id: \.self) { row in
                            
                            let dateIndex = (col * 7) + row - startDateOffset
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: width, height: width)
                                    .universalStyledBackgrond(.secondary, onForeground: true)
                                
                                if dateIndex > 0 && dateIndex <= numberOfDays {
                                    DayView(startDate: startDate,
                                            index: dateIndex,
                                            width: width,
                                            maxSaturation: maxSaturation,
                                            color: color,
                                            forPreview: forPreview,
                                            getValue: getValue)
                                }
                            }
                        }
                    }
                }
            }
        }
//        .frame(height: 8 * width)
        .defaultScrollAnchor(.trailing)
    }
}
