//
//  UniversalForm.swift
//  Recall
//
//  Created by Brian Masse on 7/19/23.
//

import Foundation
import SwiftUI
import UIUniversals

//This file contains form components and styles used across the app to make the more consistent and easier to acess
//MARK: Basic



//MARK: Color Picker
//a way to select colors, with a default pallette provided by the app
struct ColorPickerOption: View {
    let color: Color
    @Binding var selectedColor: Color
    
    static let size: CGFloat = 20
    
    var body: some View {
        Circle()
            .foregroundColor(color)
            .frame(width: ColorPickerOption.size, height: ColorPickerOption.size)
            .padding(7)
            .if(color == selectedColor) { view in
                view.rectangularBackground(5, style: .secondary, cornerRadius: 100)
            }
            .onTapGesture { withAnimation { selectedColor = color } }
    }
}


struct StyledColorPicker: View {
    let label: String
    @Binding var color: Color
    
    var body: some View {
        
        VStack(alignment: .leading) {
            UniversalText( label, 
                           size: Constants.formQuestionTitleSize,
                           font: Constants.titleFont )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Spacer()
                    ForEach(Colors.colorOptions.indices, id: \.self) { i in
                        ColorPickerOption(color: Colors.colorOptions[i], selectedColor: $color)
                    }
                    ColorPicker("", selection: $color)
                    Spacer()
                }
            }
        }
    }
}

//MARK: StyledURLField
//"https://github.com/Brian-Masse"
struct StyledURLField: View {
    
    let title: String
    let prompt: String
    
    @State private var text: String
    @Binding private var url: URL?
    
    @State private var isFocussed: Bool = false
    @State private var showingURL: Bool = false
    
    init( _ title: String, binding: Binding<URL?>, prompt: String = "" ) {
        self.title = title
        self._url = binding
        self.text = binding.wrappedValue?.absoluteString ?? ""
        self.prompt = prompt
    }
    
    private var showingCompleteButton: Bool {
        self.isFocussed && !self.text.isEmpty
    }
    
    private func getURL() {
        if let url = URL(string: self.text) {
            self.url = url
            self.showingURL = true
        }
    }
    
    var body: some View {
        HStack {
            if !showingURL || url == nil {
                StyledTextField(title: title, binding: $text, prompt: prompt, clearable: true, isFocussed: $isFocussed, shouldFocusOnAppear: true)
                    .onChange(of: self.text) {
                        if self.text.isEmpty { withAnimation {
                            self.url = nil
                            self.showingURL = false
                            self.isFocussed = false
                        }}
                    }
                
                if showingCompleteButton {
                    UniversalButton {
                        RecallIcon( "checkmark" )
                            .rectangularBackground(style: .secondary)
                            .transition(.blurReplace)
                        
                    } action: { self.getURL() }
                }
                
            } else {
                UniversalButton {
                    HStack {
                        RecallIcon("link")
                        
                        Link(self.url!.lastPathComponent, destination: self.url!)
                            .font(.custom( SyneMedium.shared.postScriptName, size: Constants.UIDefaultTextSize))
                            .lineLimit(1)
                            .foregroundStyle(.foreground)
                        Spacer()
                        
                    }
                    .opacity(0.75)
                } action: {
                    self.showingURL = false
                    self.isFocussed = true
                }
                .transition(.blurReplace)
            }
        }
        .onAppear { showingURL = !self.text.isEmpty }
        
        .animation(.easeInOut, value: self.isFocussed)
        .animation(.easeInOut, value: self.text)
        
        .onChange(of: self.isFocussed) {
            if !self.isFocussed { self.getURL() }
        }
    }
}

//MARK: StyledTextField
struct StyledTextField: View {
    
    enum TextFieldType {
        case regular
        case multiLine
        case secure
    }
    
    let title: String
    let binding: Binding<String>
    let prompt: String
    let clearable: Bool
    let type: TextFieldType
    
    let shouldFocusOnAppear: Bool
    
    @Binding var isFocussed: Bool
    
    init(
        title: String,
        binding: Binding<String>,
        prompt: String = "",
        clearable: Bool = false,
        type: TextFieldType = .regular,
        isFocussed: Binding<Bool> = .constant(false),
        shouldFocusOnAppear: Bool = false
    ) {
        self.title = title
        self.binding = binding
        self.clearable = clearable
        self.type = type
        self.prompt = prompt
        self._isFocussed = isFocussed
        self.shouldFocusOnAppear = shouldFocusOnAppear
    }
    
    @Environment(\.colorScheme) var colorScheme
    @FocusState var focused: Bool
    @State var showingClearButton: Bool = false
    
    @ViewBuilder
    private func makeTextField() -> some View {
        switch type {
        case .regular: TextField(prompt, text: binding)
        case .multiLine: TextField(prompt, text: binding, axis: .vertical)
        case .secure: SecureField(prompt, text: binding)
        }
    }
    
    @MainActor
    private func updateClearButton() { withAnimation {
        self.showingClearButton = focused && clearable && !binding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    } }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 5) {
            if !title.isEmpty {
                UniversalText(title,
                              size: Constants.formQuestionTitleSize,
                              font: Constants.titleFont)
                .padding(.trailing)
            }
            
            ZStack(alignment: .topTrailing) {
                makeTextField()
                    .focused($focused)
                    .lineLimit(1...)
                    .font(Font.custom(SyneMedium.shared.postScriptName, size: Constants.UIDefaultTextSize))
                    .frame(maxWidth: .infinity)
                    .tint(Colors.getAccent(from: colorScheme) )
                    .padding(.trailing, ( type != .regular ? 0 : ( showingClearButton ? 25 : 0 ) ) + 5 )
                
                    .rectangularBackground(style: .secondary)
                    .onChange(of: self.focused) {
                        self.updateClearButton()
                        withAnimation { self.isFocussed = self.focused }
                    }
                    .onChange(of: binding.wrappedValue) { self.updateClearButton() }
                    .onChange(of: self.isFocussed) { withAnimation { self.focused = self.isFocussed }}
                    .zIndex(0)
                
                if showingClearButton  {
                    UniversalButton {
                        RecallIcon("xmark")
                            .padding()
                            .padding(.top, 1)
                    } action: { binding.wrappedValue = "" }
                        .zIndex(100)
                        .transition(.blurReplace)
                }
            }
            .onAppear { if shouldFocusOnAppear {
                self.focused = true
            }}
        }
    }
}

//MARK: StyleSlider
struct StyledSlider: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let minValue: Float
    let maxValue: Float
    
    let binding: Binding<Float>
    let strBinding: Binding<String>
    
    let textFieldWidth: CGFloat
    
    var body: some View {
        HStack {
            Slider(value: binding, in: minValue...maxValue )
                .tint(Colors.getAccent(from: colorScheme))
            
            TextField("", text: strBinding)
                .rectangularBackground(style: .secondary)
                .universalTextField()
                .frame(width: textFieldWidth)
        }
    }
}

//MARK: SlideWithPrompt
struct SliderWithPrompt: View {
    
    let label: String
    
    let minValue: Float
    let maxValue: Float
    
    let binding: Binding<Float>
    let strBinding: Binding<String>
    
    let textFieldWidth: CGFloat
    let size: Double
    
    init(label: String, minValue: Float, maxValue: Float, binding: Binding<Float>, strBinding: Binding<String>, textFieldWidth: CGFloat, size: Double = Constants.formQuestionTitleSize) {
        
        self.label = label
        self.minValue = minValue
        self.maxValue = maxValue
        self.binding = binding
        self.strBinding = strBinding
        self.textFieldWidth = textFieldWidth
        self.size = size
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            UniversalText(label, size: size, font: Constants.titleFont)
            
            StyledSlider(minValue: minValue, maxValue: maxValue, binding: binding, strBinding: strBinding, textFieldWidth: textFieldWidth)
        }
    }
}

//MARK: Time Selector
//Time selectors can either be a single slider, or, if the fineTimeSelection preference is selected, then it will use 2 sliders to make precise time slection easier
struct TimeSelector: View {
    
    let label: String
    @Binding var time: Date
    @State var showingFineSelector: Bool = RecallModel.index.defaultFineTimeSelector
    
    let size: Double
    
    static let fineSnappingInterval: Double = 5
    
    init( label: String, time: Binding<Date>, size: Double = Constants.formQuestionTitleSize ) {
        self.label = label
        self._time = time
        self.size = size
    }
    
//    when using the fine time slider, this function will round the slide value to a specific interval. The default is set to 5
    private func roundFineTime( _ value: Double ) -> Double {
        (value / TimeSelector.fineSnappingInterval).rounded(.down) * TimeSelector.fineSnappingInterval
    }
    
    private var timeBinding: Binding<Float> {
        Binding { Float(time.getHoursFromStartOfDay().round(to: 2)) }
        set: { newValue, _ in
            time = time.dateBySetting(hour: Double(newValue)).round(to: RecallModel.index.dateSnapping)
        }
    }
    
    private var timeLabel: Binding<String> {
        Binding { time.formatted(date: .omitted, time: .shortened) }
        set: { newValue, _ in }
    }
    
//    fine time bindings
    private var fineTimeHourBinding: Binding<Float> {
        Binding { Float(time.getHoursFromStartOfDay().rounded(.down) ) }
        set: { newValue, _ in time = time.dateBySetting(hour: Double(newValue), ignoreMinutes: true) }
    }
    
    private var fineTimeBinding: Binding<Float> {
        Binding { Float( roundFineTime(time.getMinutesFromStartOfHour()) ) }
        set: { newValue, _ in
            time = time.dateBySetting(minutes:  roundFineTime( Double(newValue) )  )
        }
    }
    
    private var fineTimeLabel: Binding<String> {
        Binding { "\(Int(roundFineTime( time.getMinutesFromStartOfHour() )))" }
        set: { newValue, _ in }
    }
    
    var body: some View {
        
        VStack {
            
            HStack {
               
                UniversalText(label,
                              size: size,
                              font: Constants.titleFont)
                    .padding(.trailing, 5)
                
                Spacer()
            }
        
            if !showingFineSelector {
                StyledSlider(minValue: 0,
                             maxValue: 23.75,
                             binding: timeBinding,
                             strBinding: timeLabel,
                             textFieldWidth: 120)
                
            } else {
                StyledSlider(minValue: 0,
                             maxValue: 23.75,
                             binding: fineTimeHourBinding,
                             strBinding: timeLabel,
                             textFieldWidth: 120)
                
                StyledSlider(minValue: 0,
                             maxValue: 55,
                             binding: fineTimeBinding,
                             strBinding: fineTimeLabel,
                             textFieldWidth: 120)
            }
        }
    }
}

//MARK: Length Selector
//like a TimeSelector, LengthSelectors can either be a single slider, or, if the fineTimeSelection preference is selected, then it will use 2 sliders to make precise time slection easier
struct LengthSelector: View {
    
    let label: String
    let fontSize: Double
    let onSetLengthAction: (Double) -> Void
    let allowFineToggle: Bool
    
    @Binding var length: Double
    @State var showingFineSelector: Bool = RecallModel.index.defaultFineTimeSelector
    
    init( _ label: String, length: Binding<Double>, fontSize: Double = Constants.formQuestionTitleSize, allowFineToggle: Bool = true, onSetLengthAction: @escaping (Double) -> Void = { _ in } ) {
        self.label = label
        self._length = length
        self.fontSize = fontSize
        self.allowFineToggle = allowFineToggle
        self.onSetLengthAction = onSetLengthAction
    
    }
    
//    returns (hours, minutes)
    private func getComponents() -> (Double, Double) {
        let hours = length / Constants.HourTime
        let intHours = hours.rounded(.down)
        let minutes = (hours - intHours) * 60
        return (intHours, minutes)
    }
    
//    Standard Bindings
    private var eventLengthBinding: Binding<Float> {
        Binding { Float( length ) }
        set: { newValue, _ in
            let multiplier = 15 * Constants.MinuteTime
            length = (Double( newValue ) / multiplier).rounded(.down) * multiplier
            onSetLengthAction(length)
        }
    }
    
    private var eventLengthLabelBinding: Binding<String> {
        Binding {
            let components = getComponents()
            return "\(Int(components.0)) HR \(Int(components.1)) mins"
        } set: { newValue, _ in }
    }
    
//    fine bindings
    private var hourBinding: Binding<Float> {
        Binding { Float(getComponents().0 * Constants.HourTime) }
        set: { newValue, _ in
            let minutes = getComponents().1
            let roundedHours = (Double(newValue) / Constants.HourTime).rounded(.down) * Constants.HourTime
            length = roundedHours + ( minutes * Constants.MinuteTime )
            onSetLengthAction(length)
        }
    }
    
    private var minuteBinding: Binding<Float> {
        Binding { Float(getComponents().1 * Constants.MinuteTime) }
        set: { newValue, _ in
            let hours = getComponents().0
            let scalar: Double = (15 * Constants.MinuteTime )
            let rounded = (Double(newValue) / scalar).rounded(.down) * scalar
            length = ( hours * Constants.HourTime ) + rounded
            onSetLengthAction(length)
        }
    }
    
    private var hourLabelBinding: Binding<String> {
        Binding { "\(Int(getComponents().0)) HR" }
        set: { _, _ in }
    }
    
    private var minuteLabelBinding: Binding<String> {
        Binding { "\(Int(getComponents().1)) mins" }
        set: { _, _ in }
    }
    
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                UniversalText( label, size: fontSize, font: Constants.titleFont )
                Spacer()
                
                if allowFineToggle {
                    ConditionalLargeRoundedButton(title: "", icon: "camera.filters", wide: false, allowTapOnDisabled: true) { showingFineSelector } action: {
                        withAnimation { showingFineSelector.toggle() }
                    }
                }
            }
            
            if showingFineSelector && allowFineToggle {
                StyledSlider(minValue: 0,
                             maxValue: Float(5 * Constants.HourTime),
                             binding: hourBinding,
                             strBinding: hourLabelBinding,
                             textFieldWidth: 115)
                
                StyledSlider(minValue: 0,
                             maxValue: Float(45 * Constants.MinuteTime),
                             binding: minuteBinding,
                             strBinding: minuteLabelBinding,
                             textFieldWidth: 115)
                
            } else {
                StyledSlider(minValue: Float(15 * Constants.MinuteTime),
                             maxValue: Float(5 * Constants.HourTime),
                             binding: eventLengthBinding,
                             strBinding: eventLengthLabelBinding,
                             textFieldWidth: 150)
            }
        }
    }
}

//MARK: StyledToggle
struct StyledToggle<C: View>: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let title: C
    let wide: Bool
    let binding: Binding<Bool>
    
    init( _ binding: Binding<Bool>, wide: Bool = true, titleBuilder: () -> C ) {
        self.binding = binding
        self.title = titleBuilder()
        self.wide = wide
    }
    
    var body: some View {
        
        HStack {
            title
            
            if wide { Spacer() }
            
            Toggle("", isOn: binding)
                .tint(Colors.getAccent(from: colorScheme))
        }
    }
}

//MARK: StyledDatePicker
//In the future, this will be entirley custom built. For now it is relying on Apple's default DatePicker
struct StyledDatePicker: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var date: Date
    let title: String
    let prompt: String
    let fontSize: CGFloat
    
    init(
        _ date: Binding<Date>,
        title: String,
        prompt: String = "Select",
        fontSize: CGFloat = Constants.formQuestionTitleSize
    ) {
        self._date = date
        self.title = title
        self.prompt = prompt
        self.fontSize = fontSize
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if !title.isEmpty {
                UniversalText( title, size: fontSize, font: Constants.titleFont )
            }
            
            DatePicker(selection: $date, displayedComponents: .date) {
                UniversalText( prompt, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                    .opacity(0.25)
            }
            .tint(Colors.getAccent(from: colorScheme))
            .rectangularBackground(style: .secondary)
        }
    }
}
