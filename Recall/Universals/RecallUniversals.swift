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
func makeSectionFiller(icon: String, message: String, action: (() -> Void)?) -> some View {
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
        self.width = forPreview ? 15 : 15
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
                        
                        MonthLabel(startDate: startDate, index: (col * 7) - startDateOffset, width: width)
                            .opacity(0.5)
                        
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


//MARK: - NoiseOverlay
struct NoiseOverlay: View {
    
    private let startDate: Date = .now
    
    var body: some View {
        TimelineView(.animation) { context in
            Rectangle()
                .colorEffect(ShaderLibrary.noise(.float(startDate.timeIntervalSinceNow.round(to: 2) )))
                .blendMode(.softLight)
                .opacity(0.35)
                .ignoresSafeArea()
        }
    }
}

//MARK: - NullContentShape
struct NullContentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var rectCopy = rect
        rectCopy.size.height = 0
        
        return Path(rectCopy)
    }
}

//MARK: - RecallHiglightedBackgruond
//used for anything that can be selected
//when selected it uses the accent color, when not it uses the secondary color
//this view exists to properly match the foregroundStyle to the background
struct HiglightedBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    let padding: Double
    let active: Bool
    let disabledStyle: UniversalStyle
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle( active ? .black : ( colorScheme == .light ? .black : .white ) )
            .rectangularBackground(padding, style: active ? .accent : disabledStyle )
    }
}

extension View {
    public func highlightedBackground(_ active: Bool, padding: Double = 15, disabledStyle: UniversalStyle = .secondary) -> some View {
        modifier(HiglightedBackground(padding: padding, active: active, disabledStyle: disabledStyle))
    }
}


//MARK: - FullScreenProgressBar
struct FullScreenProgressBar: View {
    
//    MARK: ProgressBarShape
    private struct ProgressBarShape: Shape {
        var progress: Double
        let cornerRadius: Double
        
        var animatableData: Double {
            get { progress }
            set { progress = newValue }
        }
        
        func path(in rect: CGRect) -> Path {
            Path { path in

                let width: Double = rect.width - (cornerRadius * 2)
                let height: Double = rect.height - (cornerRadius * 2)
                
                let arcLength = Double.pi * cornerRadius * 0.5
                let lengths: [Double] = [ -width, height, width, -height ]
                let totalLength: Double = (arcLength * 4) + (width * 2) + (height * 2)
                var currentLength: Double = 0
                
                var drawingHorizontally = true
                
                path.move(to: .init(x: rect.maxX - cornerRadius,
                                    y: rect.minY))
                
                for i in 0..<4 {
                    
//                    determine the length of the current segment
                    let length = lengths[i]
                    let lengthDir = length / abs(length)
                    
                    var segmentLen = min( progress * totalLength,
                                                currentLength + abs(length) ) - currentLength
                    segmentLen *= lengthDir
                    
//                    draw the line
                    let startPoint = path.currentPoint ?? .zero
                    let endPointX = startPoint.x + (drawingHorizontally ? segmentLen : 0)
                    let endPointY = startPoint.y + (drawingHorizontally ? 0 : segmentLen)
                    
                    path.addLine(to: .init(x: endPointX, y: endPointY))
                    
//                    check whether this segement was complete
                    currentLength += abs(length)
                    if (currentLength / totalLength) > progress { break }
                    
                    
//                    determine the length of the current arc
                    let arcLen = min( progress * totalLength, currentLength + arcLength ) - currentLength
                    let arcPercent = arcLen / arcLength
                    
//                    draw the arc
                    let nextIndex = (i + 1) % 4
                    let nextLengthDir = lengths[nextIndex] / abs(lengths[nextIndex])
                    let basePoint = path.currentPoint ?? .zero
                    
                    let centerPoint = CGPoint(x: basePoint.x + (drawingHorizontally ? 0 : cornerRadius * nextLengthDir),
                                              y: basePoint.y + (drawingHorizontally ? cornerRadius * nextLengthDir : 0))
                    let rotation = -90 * Double(i)
                    
                    path.addArc(center: centerPoint,
                                radius: cornerRadius,
                                startAngle: .degrees(-90 + rotation),
                                endAngle: .degrees(-90 - 90 * arcPercent + rotation),
                                clockwise: true)
                    
//                    check whether this segement was complete
                    currentLength += abs(arcLength)
                    if (currentLength / totalLength) > progress { break }
                    
                    drawingHorizontally.toggle()
                }
            }
        }
    }
    
    let progress: Double
    private let cornerRadius: Double = 62
    
    @State private var thickness: Double = 7
    
    var body: some View {
        ZStack {
            ProgressBarShape(progress: progress,
                             cornerRadius: cornerRadius - (thickness / 2))
            .stroke(style: .init(lineWidth: thickness, lineCap: .round))
            .padding(thickness / 2)
            .opacity(progress > 0.05 ? 1 : 0)
        }
        .animation(.spring(duration: 1.5), value: progress)
        .ignoresSafeArea()
    }
}

//MARK: - Triangle
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: .zero)
            path.addLine(to: .init(x: rect.width, y: 0))
            path.addLine(to: .init(x: 0, y: rect.height))
            path.addLine(to: .zero)
        }
    }
}

//MARK: - GradientText
struct GradientText: View {
    
    @State private var t: Double = 0
    @State private var timer: Timer?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    private func getColors() -> [Color] {
        [ Colors.getAccent(from: .light), Colors.getAccent(from: .dark), Colors.getAccent(from: .light) ]
    }
    
    private func getTitleGradientOffset(in width: Double) -> Double {
        t.truncatingRemainder(dividingBy: width)
    }
    
    @ViewBuilder
    private func makeTitleText(_ text: String) -> some View {
        UniversalText( text, size: Constants.UIHeaderTextSize + 5, font: Constants.titleFont )
    }
    
    @ViewBuilder
    private func makeGradient() -> some View {
        LinearGradient(colors: getColors(), startPoint: .leading, endPoint: .trailing)
    }

    
    var body: some View {
        makeTitleText(text)
            .opacity(0)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        makeGradient()
                        makeGradient()
                    }
                        .frame(width: 2 * geo.size.width)
                        .offset(x: getTitleGradientOffset(in: geo.size.width))
                    
                        .onAppear {
                            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in t -= 0.5 }
                        }
                }
                .mask { makeTitleText(text) }
            }
    }
}
