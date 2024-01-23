//
//  UniversalForm.swift
//  Recall
//
//  Created by Brian Masse on 7/19/23.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: Basic


//MARK: Icon Picker

//MARK: Color Picker
struct ColorPickerOption: View {
    
    let color: Color
    @Binding var selectedColor: Color
    
    let size: CGFloat = 20
    
    var body: some View {
        
        ZStack {
            if color == selectedColor {
                Circle()
                    .foregroundColor(color)
                    .frame(width: size, height: size)
                    .padding(7)
                    .rectangularBackground(style: .primary)
            } else {
                Circle()
                    .foregroundColor(color)
                    .frame(width: size, height: size)
                    .padding(7)
            }
        }
        .onTapGesture { selectedColor = color }
    }
}

struct UniqueColorPicker: View {
    
    @Binding var selectedColor: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            UniversalText("Accent Color", size: Constants.UIDefaultTextSize)
            ScrollView(.horizontal) {
                HStack {
                    Spacer()
                    ForEach(Colors.colorOptions.indices, id: \.self) { i in
                        ColorPickerOption(color: Colors.colorOptions[i], selectedColor: $selectedColor)
                    }
                    Spacer()
                }
            }
            ColorPicker(selection: $selectedColor, supportsOpacity: false) {
                UniversalText("All Colors", size: Constants.UIDefaultTextSize)
            }
        }
    }
}


//MARK: Pickers
struct MultiPicker<ListType:Collection>: View where ListType:RangeReplaceableCollection,
                                                        ListType.Element: (Hashable),
                                                        ListType.Indices: RandomAccessCollection,
                                                        ListType.Index: Hashable {
    
    let title: String
    
    @Binding var selectedSources: ListType
    
    let sources: ListType
    let previewName: (ListType.Element) -> String?
    let sourceName: (ListType.Element) -> String?
    
    private func toggleSource(_ id: ListType.Element) {
        if let index = selectedSources.firstIndex(of: id) {
            selectedSources.remove(at: index)
        }
        else { selectedSources.append(id) }
    }
    
    private func retrieveSelectionPreview() -> String {
        if selectedSources.isEmpty { return "None" }
        if selectedSources.count == sources.count { return "All" }
        return selectedSources.reduce("") { partialResult, str in
            if partialResult == "" { return sourceName( str ) ?? "" }
            return partialResult + ", \(sourceName(str) ?? "")"
        }
    }
    
    var body: some View {
        HStack {
            UniversalText(title, size: Constants.UIDefaultTextSize, lighter: true)
            Spacer()
            
            let menu = Menu {
                Text("No Selection").tag("No Selection")
                ForEach(sources.indices, id: \.self) { i in
                    Button {
                        toggleSource(sources[i])
                    } label: {
                        let name = sourceName(sources[i])
                        if selectedSources.contains(where: { id in id == sources[i] }) { Image(systemName: "checkmark") }
                        Text( name ?? "?" ).tag(name)
                    }
                }
            } label: {
                Text( retrieveSelectionPreview())
                ResizeableIcon(icon: "chevron.up.chevron.down", size: Constants.UIDefaultTextSize)
            }.foregroundColor( Colors.tint )
                
            if #available(iOS 16.4, *) {
                menu.menuActionDismissBehavior(.disabled)
            } else {
                menu
            }
            
        }.padding(.vertical, 3)
    }
}

struct BasicPicker<ListType:RandomAccessCollection, Content: View>: View where ListType.Element: (Hashable & Identifiable)  {
    
    let title: String
    let noSeletion: String
    let sources: ListType
    
    @Binding var selection: ListType.Element
    
    @ViewBuilder var contentBuilder: (ListType.Element) -> Content

    var body: some View {

        HStack {
            UniversalText(title, size: Constants.UIDefaultTextSize, lighter: true)
            Spacer()
            
            Menu {
                Text(noSeletion).tag(noSeletion)
                ForEach( sources, id: \.id ) { source in
                    Button { selection = source } label: {
                        contentBuilder(source)
                    }.tag(source)
                }
                
            } label: {
                HStack {
                    if let str = selection as? String {
                        if str == "" { Text(noSeletion) }
                        else { contentBuilder( selection ) }
                            
                    } else {
                        contentBuilder( selection )
                    }
                    Image(systemName: "chevron.up.chevron.down")
                }
                .foregroundColor(Colors.tint)
            }
        }
    }
}

//MARK: TextFieldWithPrompt

struct TextFieldWithPrompt: View {
    
    let title: String
    let binding: Binding<String>
    let clearable: Bool
    
    init( title: String, binding: Binding<String>, clearable: Bool = false ) {
        self.title = title
        self.binding = binding
        self.clearable = clearable
    }
    
    @FocusState var focused: Bool
    @State var showingClearButton: Bool = false
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 5) {
            UniversalText(title, size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
            
            UniversalText( title, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            
            TextField("", text: binding)
                .focused($focused)
                .lineLimit(1...)
                .frame(maxWidth: .infinity)
                .padding( .trailing, 5 )
                .universalTextField()
                .rectangularBackground(style: .secondary)
                .onChange(of: self.focused) { value in
                    withAnimation { self.showingClearButton = value }
                }
            
            if showingClearButton && clearable && !binding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        UniversalText( "clear", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                        Image(systemName: "xmark")
                        Spacer()
                        
                    }
                    .rectangularBackground(style: .secondary)
                    .onTapGesture {
                        withAnimation { binding.wrappedValue = "" }
                    }
                }.transition(.opacity)
            }
        }
    }
}

//MARK: StyleSlider
struct StyledSlider: View {
    
    let minValue: Float
    let maxValue: Float
    
    let binding: Binding<Float>
    let strBinding: Binding<String>
    
    let textFieldWidth: CGFloat
    
    var body: some View {
        HStack {
            Slider(value: binding, in: minValue...maxValue )
                .tint(Colors.tint)
            
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
    
    init(label: String, minValue: Float, maxValue: Float, binding: Binding<Float>, strBinding: Binding<String>, textFieldWidth: CGFloat, size: Double = Constants.UIHeaderTextSize) {
        
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
            
            UniversalText(label, size: size, font: Constants.titleFont, true)
            
            StyledSlider(minValue: minValue, maxValue: maxValue, binding: binding, strBinding: strBinding, textFieldWidth: textFieldWidth)
        }
    }
}

//MARK: Color Picker

struct LabeledColorPicker: View {
    
    let label: String
    @Binding var color: Color
    
    var body: some View {
        
        VStack(alignment: .leading) {
            UniversalText( label, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            
            ScrollView(.horizontal) {
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



//MARK: Time Selector

struct TimeSelector: View {
    
    let label: String
    @Binding var time: Date
    @State var showingFineSelector: Bool = RecallModel.index.defaultFineTimeSelector
    
    let size: Double
    
    static let fineSnappingInterval: Double = 5
    
    init( label: String, time: Binding<Date>, size: Double = Constants.UIHeaderTextSize ) {
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
                
                ConditionalLargeRoundedButton(title: "", icon: "camera.filters", wide: false, allowTapOnDisabled: true) { showingFineSelector } action: {
                    withAnimation { showingFineSelector.toggle() }
                }
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

struct LengthSelector: View {
    
    let label: String
    let fontSize: Double
    let onSetLengthAction: (Double) -> Void
    let allowFineToggle: Bool
    
    @Binding var length: Double
    @State var showingFineSelector: Bool = RecallModel.index.defaultFineTimeSelector
    
    init( _ label: String, length: Binding<Double>, fontSize: Double = Constants.UIHeaderTextSize, allowFineToggle: Bool = true, onSetLengthAction: @escaping (Double) -> Void = { _ in } ) {
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
                .tint(Colors.tint)
        }
    }
}

//MARK: StyledDatePicker

struct StyledDatePicker: View {
    
    @Binding var date: Date
    let title: String
    let fontSize: CGFloat
    
    init( _ date: Binding<Date>, title: String, fontSize: CGFloat = Constants.UIHeaderTextSize ) {
        self._date = date
        self.title = title
        self.fontSize = fontSize
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            UniversalText( title, size: fontSize, font: Constants.titleFont )
            DatePicker(selection: $date, displayedComponents: .date) {
                UniversalText( "select", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            }
            .tint(Colors.tint)
            .rectangularBackground(style: .secondary)
        }
    }
    
    
}
