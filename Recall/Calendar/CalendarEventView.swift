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


//MARK: TestCalendarEventView
struct TestCalendarEventView: View {
    
    @ObservedObject private var calendarViewModel = RecallCalendarViewModel.shared
    @ObservedObject private var imageStoreViewModel = RecallCalendarEventImageStore.shared
    
    @Environment( \.dismiss ) var dismiss
    
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
        let decodedImages = await imageStoreViewModel.decodeImages(for: event)
        withAnimation { self.decodedImages = decodedImages }
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
            VStack(alignment: .leading) {
                UniversalText( event.title, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                UniversalText( dateLabel, size: Constants.UISubHeaderTextSize, font: Constants.mainFont )
                
                UniversalText( "see more on \(dateLabel)", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                    .opacity(0.55)
            }
            
            Spacer()
            
            makeSmallButton("chevron.down") { dismiss() }
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
                         endHour: endHour,
                         includeGestures: false)
                .padding(.leading, 25 )
                .task { await calendarViewModel.loadEvents(for: event.startTime, in: events) }
        }
        .frame(height: 150)
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
    
//    MARK: PhotoScroller
    @available(iOS 18.0, *)
    @ViewBuilder
    private func makePhotoScroller() -> some View {
        GeometryReader { geo in
            
            ZStack(alignment: .top) {
                
                Group {
                    if let image = self.decodedImages.first {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .foregroundStyle(event.getColor())
                    }
                }
                .ignoresSafeArea()
                .frame(width: geo.size.width, height: geo.size.height * 0.8)
                .contentShape(Rectangle())
                
                
                let allowsScrolling = event.images.isEmpty
                
                PhotoScrollerView (startExpanded: allowsScrolling, allowsScrolling: allowsScrolling) {
                    VStack {
                        Spacer()
                        makeHeader()
                            .foregroundStyle(.white)
                            .padding()
                    }
                    
                } bodyContent: {
                    VStack(alignment: .leading) {
                        

//                        ScrollView(.vertical) {
                        makeCalendarContainer()
                            
//                            makePhotos()
//                        }

                        Spacer()
                    }
                    .universalBackground()
                    .task { await onAppear() }
                    
                    .padding(7)
                    .clipShape(RoundedRectangle( cornerRadius: Constants.UILargeCornerRadius ))
                    .background {
                        RoundedRectangle( cornerRadius: Constants.UILargeCornerRadius )
                            .foregroundStyle(.background)
                    }
                }
            }
        }
    }
    
//    MARK: Body
    
    var body: some View {
        if #available(iOS 18.0, *) {
            
            makePhotoScroller()
            
        } else {
            // Fallback on earlier versions
        }
    }
}


#Preview {
    TestCalendarEventView(event: sampleEvent)
}
