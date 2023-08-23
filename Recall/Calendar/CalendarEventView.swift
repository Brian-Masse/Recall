//
//  CalendarEventView.swift
//  Recall
//
//  Created by Brian Masse on 7/29/23.
//

import Foundation
import SwiftUI
import RealmSwift

//MARK: Full Screen View
struct CalendarEventView: View {
    
    @ViewBuilder
    static func makeOverviewMetadataLabel(title: String, icon: String) -> some View {
        ZStack {
//            Rectangle()
//                .foregroundColor(colorScheme == .dark ? Colors.darkGrey : Colors.lightGrey)
//                .cornerRadius(Constants.UIDefaultCornerRadius)
//
            VStack {
                ResizeableIcon(icon: icon, size: Constants.UISubHeaderTextSize)
                    .padding(5)
                UniversalText(title, size: Constants.UISmallTextSize, font: Constants.mainFont)
            }
            .padding(7)
            .secondaryOpaqueRectangularBackground()
        }
    }
    
    @ViewBuilder
    static func makeOverviewView(from event: RecallCalendarEvent, in events: [RecallCalendarEvent]) -> some View {
        VStack(alignment: .leading) {
            HStack {
                makeOverviewMetadataLabel(title: "\( event.getLengthInHours().round(to: 2) ) HRs", icon: "deskclock")
                if event.isTemplate { makeOverviewMetadataLabel(title: "Tempalte", icon: "doc.plaintext") }
                makeOverviewMetadataLabel(title: "\(event.category?.label ?? "No Tag")", icon: "tag")
            }
            
            if !event.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Rectangle()
                    .opacity(0.3)
                    .frame(height: 1)
                    .padding(.bottom, 5)
                
                UniversalText( event.notes, size: Constants.UISmallTextSize, font: Constants.mainFont )
                    .padding(.horizontal, 5)
            }

            if event.goalRatings.count != 0 {
                Rectangle()
                    .opacity(0.3)
                    .frame(height: 1)
                    .padding(.bottom, 5)
                
                GoalTags(goalRatings: Array(event.goalRatings), events: events)
            }
        }
//        .secondaryOpaqueRectangularBackground(5)
        
    }
    
    @Environment( \.presentationMode ) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedRealmObject var event: RecallCalendarEvent
    let events: [RecallCalendarEvent]
 
    @State var showingEditingScreen: Bool = false
    
    var body: some View {
        
        VStack {
            let fullDate = event.startTime.formatted(date: .complete, time: .omitted)
            let times = "\( event.startTime.formatted( .dateTime.hour() ) ) - \( event.endTime.formatted( .dateTime.hour() ) )"
            
            VStack(alignment: .leading) {
            
                HStack {
                    UniversalText( event.title, size: Constants.UITitleTextSize, font: Constants.titleFont, true ).padding(.bottom, 3)
                    Spacer()
                    LargeRoundedButton("", icon: "arrow.down", color: event.getColor()) { presentationMode.wrappedValue.dismiss() }
                }
                UniversalText( fullDate, size: Constants.UIDefaultTextSize, font: Constants.mainFont ).padding(.bottom, 2)
                UniversalText( times, size: Constants.UIDefaultTextSize, font: Constants.mainFont ).padding(.bottom, 2)
                    .padding([.bottom, .trailing])

                
                UniversalText("Overview", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
                CalendarEventView.makeOverviewView(from: event, in: events)
                    .opaqueRectangularBackground()
                    .padding(.bottom)

                UniversalText("Quick Actions", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
                ScrollView(.horizontal) {
                    HStack {
                        LargeRoundedButton("edit", icon: "arrow.up.forward", color: event.getColor())                { showingEditingScreen = true }
                        LargeRoundedButton("make template", icon: "arrow.up.forward", color: event.getColor())       { event.toggleTemplate() }
                        LargeRoundedButton("delete", icon: "arrow.up.forward", color: event.getColor())              { event.delete() }
                    }
                }
                .opaqueRectangularBackground()
                .padding(.bottom)
                
                let startHour = event.startTime.getHoursFromStartOfDay()
                let endHour = min(startHour + event.getLengthInHours() + 1, 24)
                
                let currentDay = Binding { event.startTime
                } set: { _, _ in }

                
                GeometryReader { geo in
//                    CalendarContainer(at: currentDay, with: [event], from: Int(startHour), to: Int(endHour), geo: geo, scale: 0.75, background: true)
                }
            }
        }
        .padding(7)
        .sheet(isPresented: $showingEditingScreen) {
            CalendarEventCreationView.makeEventCreationView(currentDay: event.startTime, editing: true, event: event)
            
        }
        .universalBackground()
    }
}
