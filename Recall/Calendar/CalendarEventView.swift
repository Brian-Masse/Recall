//
//  CalendarEventView.swift
//  Recall
//
//  Created by Brian Masse on 7/29/23.
//

import Foundation
import SwiftUI
import RealmSwift

//MARK: DeletableCalendarEvent
private struct DeleteableCalendarEvent: ViewModifier {
    
    let event: RecallCalendarEvent
    @Binding var showingDeletionAlert: Bool
    
    func body(content: Content) -> some View {
        content
            .alert("This Event is a Template", isPresented: $showingDeletionAlert) {
                Button(role: .cancel) { showingDeletionAlert = false } label:                   { Text("cancel") }
                Button(role: .destructive) { event.delete(preserveTemplate: true) } label:      { Text("only delete event") }
                Button(role: .destructive) { event.delete() } label:                            { Text("delete event and template") }
                
            } message: {
                Text("Choose whether to delete or preserve the template associated with this event.")
            }
    }
}

extension View {
    
    func deleteableCalendarEvent(deletionBool: Binding<Bool>, event: RecallCalendarEvent ) -> some View {
        modifier( DeleteableCalendarEvent(event: event, showingDeletionAlert: deletionBool) )
    }
    
}


//MARK: CalendarEventView
struct CalendarEventView: View {

    
//    MARK: ViewBuilders
    @ViewBuilder
    private static func makeOverviewMetadataLabel(title: String, icon: String) -> some View {
        HStack {
            Spacer()
            
            VStack {
                ResizeableIcon(icon: icon, size: Constants.UISubHeaderTextSize)
                    .padding(5)
                UniversalText(title, size: Constants.UISmallTextSize, font: Constants.mainFont)
            }
            .padding(7)
            
            Spacer()
        }
        .secondaryOpaqueRectangularBackground()
    }
    
    @State var templateDeletionAlert: Bool = false
    
    @ViewBuilder
    private static func makeOverviewView(from event: RecallCalendarEvent, in events: [RecallCalendarEvent]) -> some View {
        VStack(alignment: .leading) {
            HStack {
                makeOverviewMetadataLabel(title: "\( event.getLengthInHours().round(to: 2) ) HRs", icon: "deskclock")
                if event.isTemplate { makeOverviewMetadataLabel(title: "Tempalte", icon: "doc.plaintext") }
                makeOverviewMetadataLabel(title: "\(event.category?.label ?? "No Tag")", icon: "tag")
            }.padding(.bottom, 5)
            
            if !event.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                UniversalText("Notes", size: Constants.UISubHeaderTextSize, font: Constants.titleFont, true)
                    .padding(.bottom, 5)
                
                ScrollView(.vertical) {
                    VStack {
                        UniversalText( event.notes, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                            .padding(.trailing)
                    }
                }
//                .frame(maxHeight: 250)
            }
        }
    }
    
    @ViewBuilder
    private func makePageHeader() -> some View {
        let fullDate = event.startTime.formatted(date: .complete, time: .omitted)
        let times = "\( event.startTime.formatted( date: .omitted, time: .shortened ) ) - \( event.endTime.formatted( date: .omitted, time: .shortened ) )"
        
        HStack {
            UniversalText( event.title, size: Constants.UITitleTextSize, font: Constants.titleFont, true ).padding(.bottom, 3)
            Spacer()
            LargeRoundedButton("", icon: "arrow.down", color: event.getColor()) { presentationMode.wrappedValue.dismiss() }
        }
        UniversalText( fullDate, size: Constants.UIDefaultTextSize, font: Constants.mainFont ).padding(.bottom, 2)
        UniversalText( times, size: Constants.UIDefaultTextSize, font: Constants.mainFont ).padding(.bottom, 2)
            .padding([.bottom, .trailing])

    }
    
    @ViewBuilder
    private func makeOverview() -> some View {
        
        UniversalText("Overview", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
        VStack(alignment : .leading) {

            UniversalText("Info", size: Constants.UISubHeaderTextSize, font: Constants.titleFont, true)
            CalendarEventView.makeOverviewView(from: event, in: events)
                .padding(.bottom)
            
            if event.goalRatings.count != 0 {
                UniversalText("Goal Progress", size: Constants.UISubHeaderTextSize, font: Constants.titleFont, true)
                GoalTags(goalRatings: Array(event.goalRatings), events: events)
            }
        }.opaqueRectangularBackground(7, stroke: true)
    }
    
    @ViewBuilder
    private func makeQuickActions() -> some View {
        UniversalText("Quick Actions", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
        ScrollView(.horizontal) {
            HStack {
                LargeRoundedButton("edit", icon: "arrow.up.forward", color: event.getColor())                { showingEditingScreen = true }
                LargeRoundedButton("favorite", icon: "arrow.up.forward", color: event.getColor())       { event.toggleFavorite() }
                LargeRoundedButton("template", icon: "arrow.up.forward", color: event.getColor())       { event.toggleTemplate() }
                LargeRoundedButton("delete", icon: "arrow.up.forward", color: event.getColor())         {
                    if event.isTemplate { templateDeletionAlert = true }
                }
            }
        }
        .secondaryOpaqueRectangularBackground(7)
    }
    
    @ViewBuilder
    private func makeCalendarPreview() -> some View {
        let startHour = event.startTime.getHoursFromStartOfDay()
        let endHour = min(startHour + event.getLengthInHours() + 2, 24)
        
        let currentDay = Binding { event.startTime } set: { _, _ in }
        
        GeometryReader { geo in
            CalendarContainer(at: currentDay, with: [event], from: Int(startHour), to: Int(endHour), geo: geo, scale: 0.75,
                              background: true, overrideHeight: 200)
        }.frame(height: 200)
    }
    
//    MARK: Vars
    
    @Environment( \.presentationMode ) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedRealmObject var event: RecallCalendarEvent
    let events: [RecallCalendarEvent]
 
    @State var showingEditingScreen: Bool = false
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            
            makePageHeader()
            
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    
                    makeQuickActions()
                        .padding(.bottom, 7)
                    
                    makeOverview()
                        .padding(.bottom, 7)
                    
                    makeCalendarPreview()
                        .padding(.bottom, Constants.UIBottomOfPagePadding)
                    
                }
            }
        }
        .padding(7)
        .sheet(isPresented: $showingEditingScreen) {
            CalendarEventCreationView.makeEventCreationView(currentDay: event.startTime, editing: true, event: event)
        }
        .deleteableCalendarEvent(deletionBool: $templateDeletionAlert, event: event)
        .universalBackground()
    }
}
