//
//  CalendarEventView.swift
//  Recall
//
//  Created by Brian Masse on 7/29/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals
import MapKit

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
                RecallIcon(icon)
                    .padding(5)
                UniversalText(title, size: Constants.UISmallTextSize, font: Constants.mainFont)
            }
            .padding(7)
            
            Spacer()
        }
        .rectangularBackground(style: .secondary)
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
                UniversalText("Notes", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                    .padding(.bottom, 5)
                
                ScrollView(.vertical, showsIndicators: false) {
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
            UniversalText( event.title, size: Constants.UIMainHeaderTextSize, font: Constants.titleFont ).padding(.bottom, 3)
            Spacer()
            LargeRoundedButton("", icon: "arrow.down", color: event.getColor()) { presentationMode.wrappedValue.dismiss() }
        }
        UniversalText( fullDate, size: Constants.UIDefaultTextSize, font: Constants.mainFont ).padding(.bottom, 2)
        UniversalText( times, size: Constants.UIDefaultTextSize, font: Constants.mainFont ).padding(.bottom, 2)
            .padding([.bottom, .trailing])

        if let url = URL(string: event.urlString) {
            Link(url.absoluteString, destination: url)
        }
    }
    
    @ViewBuilder
    private func makeOverview() -> some View {
        
        UniversalText("Overview", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
        VStack(alignment : .leading) {

            UniversalText("Info", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
            CalendarEventView.makeOverviewView(from: event, in: events)
                .padding(.bottom)
            
            if event.goalRatings.count != 0 {
                UniversalText("Goal Progress", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
//                TODO: This may be the same view as is present on the Tags, so you can possibly recycle that code
//                GoalTags(goalRatings: Array(event.goalRatings), events: events)
            }
        }.rectangularBackground(7, style: .primary, stroke: true)
    }
    
    @ViewBuilder
    private func makeQuickActions() -> some View {
        UniversalText("Quick Actions", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                LargeRoundedButton("edit", icon: "arrow.up.forward", color: event.getColor())                { showingEditingScreen = true }
                LargeRoundedButton("favorite", icon: "arrow.up.forward", color: event.getColor())       { event.toggleFavorite() }
                LargeRoundedButton("template", icon: "arrow.up.forward", color: event.getColor())       { event.toggleTemplate() }
                LargeRoundedButton("delete", icon: "arrow.up.forward", color: event.getColor())         {
                    if event.isTemplate { templateDeletionAlert = true }
                }
            }
        }
        .rectangularBackground(7, style: .secondary)
    }
    
    @ViewBuilder
    private func makeCalendarPreview() -> some View {
        let startHour = event.startTime.getHoursFromStartOfDay()
        let endHour = min(startHour + event.getLengthInHours() + 2, 24)
        
        GeometryReader { geo in
            StyledCalendarContainerView(at: event.startTime,
                                        with: [event],
                                        from: Int(startHour),
                                        to: Int(endHour),
                                        geo: geo,
                                        scale: 1)
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
        
        Text("hi")
        VStack(alignment: .leading) {
            
            makePageHeader()
            
            ScrollView(.vertical, showsIndicators: false) {
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

//MARK: TestCalendarEventView
struct TestCalendarEventView: View {
    
    @ObservedObject private var calendarViewModel = RecallCalendarViewModel.shared
    @ObservedObject private var imageStoreViewModel = RecallCalendarEventImageStore.shared
    
//    MARK: Vars
    let event: RecallCalendarEvent
    let events: [RecallCalendarEvent]
    
    @State private var decodedImages: [UIImage] = []
    
    @State private var position: MapCameraPosition
    @Namespace private var mapNameSpace
    
//    MARK: Init
    init( event: RecallCalendarEvent, events: [RecallCalendarEvent] = [] ) {
        self.event = event
        self.events = events
        
        if let location = event.getLocationResult() {
            self.position = MapCameraPosition.camera(.init(centerCoordinate: location.location, distance: 1000))
        } else {
            self.position = MapCameraPosition.automatic
        }
    }
    
    private func onAppear() async {
        self.decodedImages = await imageStoreViewModel.decodeImages(for: event)
    }
    
    private var timeLabel: String {
        let formatter = Date.FormatStyle().hour().minute()
        let str1 = event.startTime.formatted(formatter)
        let str2 = event.startTime.formatted(formatter)
        
        return "\(str1) - \(str2)"
    }
    
    private var dateLabel: String {
        let formatter = Date.FormatStyle().month().day()
        let str1 = event.startTime.formatted(formatter)
        let str2 = timeLabel
        
        return "\(str2), \(str1)"
    }
    
//    MARK: SmallButton
    @ViewBuilder
    private func makeSmallButton(_ icon: String, action: @escaping () -> Void) -> some View {
        UniversalButton {
            RecallIcon(icon)
                .rectangularBackground(style: .secondary)
        } action: { action() }

    }
    
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        
        HStack(spacing: 15) {
            
            makeSmallButton("chevron.left") { }
            
            VStack(alignment: .leading) {
                UniversalText( event.title, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                UniversalText( dateLabel, size: Constants.UISubHeaderTextSize, font: Constants.mainFont )
                
                UniversalText( "see more on \(dateLabel)", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                    .opacity(0.55)
            }
            
            Spacer()
        }
    }
    
//    MARK: Map
    @ViewBuilder
    private func makeMap() -> some View {
        if let location = event.getLocationResult() {
            VStack(alignment: .leading) {
                UniversalText( "Location", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                
                Map(position: $position, scope: mapNameSpace) {
                    Marker(coordinate: location.location) {
                        Text(location.title)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
                .frame(height: 300)
                
                HStack {
                    RecallIcon("location")
                    
                    UniversalText( "\(location.title)", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                }
                .opacity(0.75)
                .padding(.leading)
            }
        }
    }
    
//    MARK: CalendarContainer
    @ViewBuilder
    private func makeCalendarContainer() -> some View {
        let eventHour: Double = Double(Calendar.current.component(.hour, from: event.startTime))
        let startHour: Double = eventHour
        let endHour: Int = Int(eventHour + event.getLengthInHours()) + 1
        
        ZStack {
            
            EmptyCalendarView(startHour: Int(startHour), endHour: endHour, labelWidth: 20, includeCurrentTimeMark: false)
            
            CalendarView(events: calendarViewModel.getEvents(on: event.startTime),
                         on: event.startTime,
                         startHour: startHour,
                         endHour: endHour)
                .padding(.leading, 25 )
                .task { await calendarViewModel.loadEvents(for: event.startTime, in: events) }
        }
        .rectangularBackground(style: .secondary)
    }
    
//    MARK: Photos
    @MainActor
    @ViewBuilder
    private func makePhotos() -> some View {
        if event.images.count != 0 {
            
            ForEach( self.decodedImages, id: \.self ) { image in
                    
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
    
//    MARK: Body
    
    var body: some View {
        
        if #available(iOS 18.0, *) {
//            PhotoScrollerView {
//                VStack {
//                    
//                    Text("hi there!")
//                        .bold()
//                        .font(.title)
//                    
//                    Spacer()
//                }
//                
//            } bodyContent: {
//                LazyVStack {
//                    ForEach( 0...100, id: \.self ) { i in
//                        
//                        Rectangle()
//                            .frame(height: 50)
//                            .foregroundStyle(.red)
//                            .opacity(Double(i) / 100)
//                    }
//                }
//                
//            }
            
//            TestScroller()
        } else {
            // Fallback on earlier versions
        }

        
        VStack(alignment: .leading) {
            makeHeader()

            ScrollView(.vertical) {
                makeCalendarContainer()
                
                makePhotos()
            }

            Spacer()
        }
        .padding(7)
        .universalBackground()
        
        .task { await onAppear() }
    }
}


#Preview {
    TestCalendarEventView(event: sampleEvent)
}
