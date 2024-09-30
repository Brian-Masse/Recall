//
//  CactusTimeDial.swift
//  CactusComponents
//
//  Created by Brian Masse on 9/10/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: CactusTimeDial
struct CactusTimeDial: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var dialNamespace
    @ObservedObject private var viewModel = TimeDialViewModel.shared
    
    private let id: String = UUID().uuidString
    private let timePromptId = "timePromptId"
    
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    
    @Binding var time: Date
    
    @State private var postMeridian: Bool = false
    @State private var currentMeridianSwitch: Int = 0
    @State private var selectingHour: Bool = true
    
    @State private var currentLinearProgress: Double = -100
    @State private var currentAngularProgress: Double = -100
    
    @State private var showingDial: Bool = false
    
    private let aspectRatio: Double = 2
    private let circleSize: Double = 55
    
    let title: String
    
//    MARK: ViewModel
    private class TimeDialViewModel: ObservableObject {
        static let shared = TimeDialViewModel()
        
        @Published var currentlyPresentedDial: String = ""
    }
    
//    MARK: Convenience Vars
    private var currentDay: Date {
        time.resetToStartOfDay()
    }
    
    private var currentHour: Double {
        Double(Calendar.current.component(.hour, from: time))
    }
    
    private var currentMinute: Double {
        Double(Calendar.current.component(.minute, from: time))
    }
    
//    MARK: Format
    private func formatHour(_ hour: Double) -> String {
        return (Calendar.current.date(bySetting: .hour, value: Int(hour), of: .now) ?? .now).formatted(Date.FormatStyle().hour(.twoDigits(amPM: .omitted)))
    }
    
    private func formatMinute(_ minute: Double) -> String {
        return (Calendar.current.date(bySetting: .minute, value: Int(minute), of: .now) ?? .now).formatted(Date.FormatStyle().minute(.twoDigits))
    }
    
//    MARK: Angles and Translations
    ///measured in radians
    private func getHourAngle(of time: Double) -> Double { (time.truncatingRemainder(dividingBy: 12) / 12) * Double.pi }
    
    private func getMinuteAngle(of time: Double) -> Double { (time / 60) * Double.pi }
    
    private func getTranslation(in radius: Double, using angle: Double) -> CGSize {
        let x = cos(angle) * radius
        let y = sin(angle) * radius / (aspectRatio / 2)
        return .init(width: -x, height: -y)
    }

    private func roundMinute(_ minute: Double) -> Double { round(minute / 5) * 5 }
    
//    MARK: Setters
    private func setHour( _ hour: Double ) {
        let hourValue = (Int(hour) % 12) + ( !postMeridian ? 0 : 12 )
        let minuteValue = Calendar.current.component(.minute, from: time)
            
        self.time = Calendar.current.date(bySettingHour: hourValue, minute: minuteValue, second: 0, of: time) ?? time
    }
    
    private func setMinute( _ minute: Double ) {
        let minuteValue = Int(roundMinute(minute)) % 60
        
        self.time = Calendar.current.date(bySettingHour: Int(currentHour), minute: minuteValue, second: 0, of: time) ?? time
    }
    
    
//    MARK: TimeMarker
    @ViewBuilder
    private func makeTimeMarker(in radius: Double) -> some View {
        
        let angle = selectingHour ? getHourAngle(of: currentHour) : getMinuteAngle(of: currentMinute)

        VStack(spacing: 0) {
            Circle()
                .frame(width: circleSize, height: circleSize)
            
            Rectangle()
                .foregroundStyle(.clear)
                .frame(width: 2, height: radius - circleSize  / 2)
        }
        .foregroundStyle(Colors.getAccent(from: colorScheme))
        .rotationEffect(.radians(angle - (Double.pi / 2)), anchor: .bottom)
        
    }
    
//    MARK: Labels
    @ViewBuilder
    private func makeDigitLabel(_ title: String) -> some View {
        UniversalText( title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            .opacity(0.75)
            .frame(width: 30, height: 30)
            .contentShape(DialClipMask())
    }
    
    @ViewBuilder
    private func makeHourLabel(_ hour: Double, in radius: Double) -> some View {
        
        let translation = getTranslation(in: radius, using: getHourAngle(of: hour))
        let label = formatHour(hour)
        
        makeDigitLabel(label)
            .transition(.rotation(radius: radius, hour: hour))
            .offset(x: translation.width, y: translation.height + 15)
            .onTapGesture {
                    setHour(hour)
                    selectingHour = false
            }
    }
    
    @ViewBuilder
    private func makeHourLabels( in radius: Double ) -> some View {
        let offset = !postMeridian ? 0 : 12
        
        ZStack {
            ForEach( 0..<12, id: \.self ) { i in
                let hour = offset + i
                
                makeHourLabel(Double(hour), in: radius)
                    .id(hour)
            }
        }
    }
    
//    MARK: MinuteLabels
    @ViewBuilder
    private func makeMinuteLabel(_ minute: Double, in radius: Double) -> some View {
        let translation = getTranslation(in: radius, using: getMinuteAngle(of: minute))
        let label = formatMinute(minute)
        
        makeDigitLabel(label)
            .offset(x: translation.width, y: translation.height + 15)
            .onTapGesture { setMinute(minute) }
    }
    
    @ViewBuilder
    private func makeMinuteLabels( in radius: Double ) -> some View {
        ZStack {
            ForEach( 0..<12, id: \.self ) { i in
                let minute = i * ( 60 / 12 )
                
                makeMinuteLabel(Double(minute), in: radius)
                
            }
        }
    }
    
//    MARK: PlaneControl
    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: .init(x: rect.midX, y: rect.maxY))
                path.addLine(to: .init(x: rect.maxX, y: rect.maxY))
            }
        }
    }
    
    @ViewBuilder
    private func makePlaneControl(in radius: Double) -> some View {
        ZStack(alignment: .bottom) {
        
            Rectangle()
                .foregroundStyle(.clear)
            
            let count = 36
         
            ForEach( 0...count, id: \.self ) { i in
                    
                let angle = Double(i) / Double(count) * Double.pi
                let even = i % 3 == 0
                
                let difference = abs((Double(i) / Double(count)) - self.currentAngularProgress)
                let proposedOpacity = (1 / (difference * 15 + 0.5) )
                let opacity = min(max( 0.1, proposedOpacity ), 1)
                
                let proposedScale = (1 / (difference * 10) )
                let scale = min(max( 0.3, proposedScale ), 1)  * 0.4 + 0.6

                HStack {
                    Spacer()
                    
                    Line()
                        .stroke(style: .init(lineWidth: 5, lineCap: .round) )
                        .frame(width: 20 + (even ? 10 : 0))
                        .opacity( currentAngularProgress == -100 ? ( even ? 0.4 : 0.25 ) : opacity )
                        .scaleEffect(x: scale, anchor: .trailing)
                        .padding(.trailing, 30)
                }
                .rotationEffect(.init(radians: -angle), anchor: .bottom)
            }
        }
        .animation(.easeInOut, value: currentAngularProgress)
    }
    
//    MARK: LinearControl
    @ViewBuilder
    private func makeLinearControl() -> some View {
        GeometryReader { geo in
            ZStack {
                Rectangle()
                    .foregroundStyle(.clear)
                    .contentShape(Rectangle())
                
                HStack(spacing: 7) {
                    let count = 24
                    
                    RecallIcon("chevron.left")
                        .opacity(0.2)
                    
                    ForEach( 0...count, id: \.self ) { i in
                        
                        let difference = abs((Double(i) / Double(count)) - self.currentLinearProgress)
                        let proposedOpacity = (1 / (difference * 15 + 0.5) )
                        let opacity = min(max( 0.1, proposedOpacity ), 1)
                        
                        let proposedScale = (1 / (difference * 10) )
                        let scale = min(max( 0.3, proposedScale ), 1)  * 0.4 + 0.6
                        
                        RoundedRectangle(cornerRadius: 25)
                            .opacity(currentLinearProgress == -100 ? 0.2 : opacity)
                            .scaleEffect(y: currentLinearProgress == -100 ? 0.8 : scale)
                    }
                    
                    RecallIcon("chevron.right")
                        .opacity(0.2)
                }
                .bold()
            }
            .gesture(linearGesture(in: geo.size.width / 2))
            .animation(.easeInOut, value: currentLinearProgress)
        }
        .frame(height: 20)
    }
    
//    MARK: Plane Gesture
    private func togglePlaneGestureMeridian(from position: Double) {
        if position > 0 && currentMeridianSwitch != 0  {
            postMeridian.toggle()
            currentMeridianSwitch = 0
        }
        if position < 0 && currentMeridianSwitch != 1 {
            postMeridian.toggle()
            currentMeridianSwitch = 1
        }
    }
    
    private func planeGesture(in radius: Double) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let x = value.location.x - radius
                let y = radius - value.location.y
                
                let measuredAngle = atan( y / x )
                let angle = measuredAngle < 0 ? Double.pi + measuredAngle : measuredAngle
                let fraction = angle / Double.pi
                
                self.currentAngularProgress = fraction
                
                if Int(currentAngularProgress * 100) % 5 == 0 {
                    self.rigidImpact.impactOccurred(intensity: 0.5)
                }
                
                if selectingHour {
                    togglePlaneGestureMeridian(from: y)
                    let hourValue = 12 - fraction * 12
                    self.setHour(hourValue)
                    
                } else {
                    let minuteValue = 60 - fraction * 60
                    self.setMinute(minuteValue)
                }
            }
        
            .onEnded { _ in
                self.selectingHour = false
                self.currentMeridianSwitch = 0
                self.currentAngularProgress = -100
            }
    }
    
//    MARK: LinearGesture
    private func toggleLinearGestureMeridian(from fraction: Double) {
        if fraction > 0.5 && !postMeridian { postMeridian = true }
        if fraction < 0.5 && postMeridian { postMeridian = false }
    }
    
    private func linearGesture(in radius: Double) -> some Gesture {
        DragGesture()
            .onChanged { value in
                self.currentLinearProgress = value.location.x / (radius * 2)
                
                if Int(currentLinearProgress * 100) % 5 == 0 {
                    self.rigidImpact.impactOccurred(intensity: 0.5)
                }
                
                if selectingHour {
                    toggleLinearGestureMeridian(from: currentLinearProgress)
                    let hourValue = ( currentLinearProgress * 24 )
                    self.setHour(hourValue)
                    
                } else {
                    let minuteValue = ( currentLinearProgress * 60 )
                    self.setMinute(minuteValue)
                }
            }
        
            .onEnded { _ in
                self.selectingHour = false
                withAnimation { self.currentLinearProgress = -100 }
            }
    }
    
//    MARK: Time Preview
    @ViewBuilder
    private func makeTimePreviewText(_ text: String, action: @escaping () -> Void) -> some View {
        UniversalButton {
            UniversalText( text, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                .rectangularBackground(style: .secondary)
            
        } action: { action() }
    }
    
    @ViewBuilder
    private func makeMeridianSelector() -> some View {
        UniversalButton {
            UniversalText( postMeridian ? "PM" : "AM", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
        } action: { postMeridian.toggle() }
    }
    
    @ViewBuilder
    private func makeTimePreview() -> some View {
        HStack(spacing: 5) {
            makeTimePreviewText(formatHour(currentHour)) { selectingHour = true }
            
            UniversalText( ":", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            
            makeTimePreviewText(formatMinute(currentMinute)) { selectingHour = false }
            
            makeMeridianSelector()
        }
        .frame(minWidth: 175, alignment: showingDial ? .center : .trailing)
        .animation(nil, value: postMeridian)
        .animation(nil, value: time)
    }
    
//    MARK: header
    @ViewBuilder
    private func makeHeader() -> some View {
        ZStack(alignment: .trailing) {
            HStack {
                UniversalText( title, size: Constants.formQuestionTitleSize, font: Constants.titleFont )
                Spacer(minLength: 150)
            }
            .onTapGesture { showingDial.toggle() }
            
            if !showingDial {
                makeTimePreview()
                    .matchedGeometryEffect(id: timePromptId, in: dialNamespace)
                    .overlay {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { showingDial = true }
                    }
            }
        }
    }
    
//    MARK: Transitions
    struct RotationTransitionViewModifier: ViewModifier, Animatable {
        var angle: Double
        
        let radius: Double
        let hour: Double
        
        var animatableData: Double {
            get { self.angle }
            set { self.angle = newValue }
        }
        
        func body(content: Content) -> some View {
            
            let angle = (hour.truncatingRemainder(dividingBy: 12) / 12) * Double.pi
            let resetX = cos(angle) * radius
            let resetY = sin(angle) * radius
            
            let newAngle = (hour.truncatingRemainder(dividingBy: 12) / 12) * Double.pi + animatableData
            let x = cos(newAngle) * radius
            let y = sin(newAngle) * radius
            
            content
                .blur(radius: (self.angle / Double.pi) * 5)
                .offset(x: resetX - x, y: resetY - y)
        }
    }
    
//    MARK: FullDialLayout
    private struct DialClipMask: Shape {
        let padding: Double = 12
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: .init(x: rect.minX - padding, y: rect.minY - padding))
                path.addLine(to: .init(x: rect.maxX + padding, y: rect.minY - padding))
                path.addLine(to: .init(x: rect.maxX + padding, y: rect.maxY + padding))
                path.addLine(to: .init(x: rect.minX - padding, y: rect.maxY + padding))
                path.addLine(to: .init(x: rect.minX - padding, y: rect.minY - padding))
            }
        }
    }
    
    @ViewBuilder
    private func makeFullDialLayout() -> some View {
        GeometryReader { geo in
            let radius = geo.size.width / 2
            
            Rectangle()
                .foregroundStyle(.clear)
                .contentShape(Rectangle())
                .highPriorityGesture(planeGesture(in: radius ))
            
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .foregroundStyle(.clear)
                    
                    if selectingHour { makeHourLabels(in: radius) }
                    else { makeMinuteLabels(in: radius) }
                }
                .clipShape(DialClipMask())
            }
            .overlay(alignment: .bottom) {
                makeTimePreview()
                    .matchedGeometryEffect(id: timePromptId, in: dialNamespace)
                    .padding(.bottom)
            }
            .background(alignment: .bottom ) {
                ZStack(alignment: .bottom) {
                    makePlaneControl(in: radius)
                    makeTimeMarker(in: radius)
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.easeInOut(duration: 1), value: postMeridian)
        .animation(.easeInOut, value: selectingHour)

        .padding([.bottom, .horizontal])
        .aspectRatio(aspectRatio - 0.2, contentMode: .fit)
        .onAppear { viewModel.currentlyPresentedDial = id }
        
        makeLinearControl()
            .padding(.horizontal, 30)
            .padding(.bottom, 7)
    }
    
//    MARK: Body
    var body: some View {
        
        VStack(spacing: 0) {
            makeHeader()

            if showingDial {
                makeFullDialLayout()
            }
        }
        .animation(.spring, value: showingDial)
        .onAppear { withoutAnimation { postMeridian = currentHour > 12 } }
        .onChange(of: viewModel.currentlyPresentedDial) {
            if viewModel.currentlyPresentedDial != id { self.showingDial = false }
        }
    }
}

extension AnyTransition {
    static func rotation(radius: Double, hour: Double) -> AnyTransition {
        .asymmetric(insertion: .modifier(active: CactusTimeDial.RotationTransitionViewModifier(angle: -Double.pi, radius: radius, hour: hour),
                                         identity: CactusTimeDial.RotationTransitionViewModifier(angle: 0, radius: radius, hour: hour)),
                    
                    removal: .modifier(active: CactusTimeDial.RotationTransitionViewModifier(angle: Double.pi, radius: radius, hour: hour),
                                       identity: CactusTimeDial.RotationTransitionViewModifier(angle: 0, radius: radius, hour: hour))
        )
        .combined(with: .opacity)
    }
}

struct CactusTimeDialDemoView: View {
    
    var body: some View {
        
        VStack {
//            CactusTimeDial()
//            
//            CactusTimeDial()
        }
    }
}

#Preview {
    CactusTimeDialDemoView()
}
