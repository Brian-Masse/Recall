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
struct CalendarComponentPreviewView: View {
    
    enum TimeRounding: Int {
        case hour = 1
        case halfHour = 2
        case querter = 4
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedRealmObject var component: RecallCalendarComponent
    let spacing: CGFloat
    
    @State var startDate: Date = .now
    @State var endDate: Date = .now
    @State var roundedStartDate: Date = .now
    @State var roundedEndDate: Date = .now
    
    @State var offSet: CGFloat = 0  //is a position
    @State var length: CGFloat = 0  //measured in hours
    
    @State var dragging: Bool = false
    
    private var drag: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { dragGesture in
                dragging = true
                offSet = dragGesture.location.y
                
                startDate = getTime(from: dragGesture.location.y)
                endDate   = startDate + (length * Constants.HourTime)
                
                roundedStartDate = getNearestTime(from: dragGesture.location.y, to: .halfHour)
                roundedEndDate   = roundedStartDate + (length * Constants.HourTime)
            }
            .onEnded { dragGesture in
                dragging = false
                
                component.updateDate(startDate: roundedStartDate, endDate: roundedEndDate)
            }
    }
    
    private func getTime(from position: CGFloat) -> Date {
        let hour = (position / spacing).rounded(.down)
        let minutes = ((position / spacing) - hour) * CGFloat(Constants.MinuteTime)
        
        return Calendar.current.date(bySettingHour: Int(hour), minute: Int(minutes), second: 0, of: startDate) ?? .now
    }
    
    private func getNearestTime(from position: CGFloat, to timeRounding: TimeRounding) -> Date {
        let hour = (position / spacing).rounded(.down)
        let minutes = ((position / spacing) - hour)
        let roundedMinutes = ((minutes * CGFloat(timeRounding.rawValue)).rounded(.down) / CGFloat(timeRounding.rawValue)) * CGFloat(Constants.MinuteTime)
        
        return Calendar.current.date(bySettingHour: Int(hour), minute: Int(roundedMinutes), second: 0, of: startDate) ?? .now
    }
    
    
    private func setup() {
        startDate = component.startTime
        endDate = component.endTime
        
        let startTime = component.startTime.getHoursFromStartOfDay()
        let endTime = component.endTime.getHoursFromStartOfDay()
        length = endTime - startTime
        offSet = CGFloat(startTime) * spacing
    }
    
    var body: some View {
            
        ZStack {
            
            if dragging {
                Rectangle()
                    .foregroundColor(.red.opacity(0.5))
                    .cornerRadius(Constants.UIDefaultCornerRadius)
                    .frame(height: CGFloat(length) * spacing)
                    .offset(y: roundedStartDate.getHoursFromStartOfDay() * spacing)
            }
            
            VStack {
                UniversalText( component.title, size: Constants.UISubHeaderTextSize, true )
                UniversalText( component.ownerID, size: Constants.UIDefaultTextSize )
                
                HStack {
                    
                    UniversalText( startDate.formatted(date: .omitted, time: .complete), size: Constants.UIDefaultTextSize )
                    Spacer()
                    UniversalText( endDate.formatted(date: .omitted, time: .complete), size: Constants.UIDefaultTextSize )
                }
                
            }
            .padding()
            .frame(height: CGFloat(length) * spacing)
            .background(colorScheme == .light ? .white : Colors.darkGrey )
            .cornerRadius(Constants.UIDefaultCornerRadius)
            .offset(y: offSet)
            .gesture(drag)
            .onAppear { setup() }
        }
    }
}


struct CalendarComponentView: View {
    
    @Environment( \.presentationMode ) var presentationMode
    @ObservedRealmObject var component: RecallCalendarComponent
 
    @State var editing: Bool = false
    
    @State var startDate: Date
    @State var endDate: Date
    
    var body: some View {
        
        VStack {
                
            HStack {
                
                ShortRoundedButton("Dismiss", icon: "chevron.down") { presentationMode.wrappedValue.dismiss() }
                Spacer()
                UniversalText( component.title, size: Constants.UISubHeaderTextSize, true )
//                Spacer()
//                ShortRoundedButton("Edit", to: "Done", icon: "pencil", to: "checkmark.seal", completed: { editing }) { editing.toggle() }
                
            }
            
            DatePicker(selection: $startDate, displayedComponents: [.hourAndMinute]) { Text("Start Date") }
            
            DatePicker(selection: $endDate, displayedComponents: [.hourAndMinute]) { Text("End Date") }
            
            RoundedButton(label: "Done", icon: "checkmark.seal") {
                component.update(title: component.title, startDate: startDate, endDate: endDate)
            }
            
        }
        .padding()
        .universalBackground()
    }
}
