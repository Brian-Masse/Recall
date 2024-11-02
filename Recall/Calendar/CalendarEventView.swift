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
    
    @Environment( \.colorScheme ) var colorScheme
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
    private func makeSmallButton(_ icon: String, label: String = "", action: @escaping () -> Void) -> some View {
        UniversalButton {
            HStack {
                RecallIcon(icon)
                    .frame(width: 10)
            
                if !label.isEmpty {
                    UniversalText(label, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
                }
            }
            .frame(height: 10)
            .font(.callout)
            .rectangularBackground(12, style: .transparent)
        } action: { action() }

    }
    
//    MARK: sectionHeader
    @ViewBuilder
    private func makeSectionHeader(_ icon: String, title: String) -> some View {
        HStack {
            RecallIcon(icon)
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            Spacer()
        }
        .padding(.leading)
        .opacity(0.75)
    }
    
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        
        HStack(spacing: 10) {
            VStack(alignment: .leading) {
                UniversalText( event.title, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                    .lineLimit(2)
                    .foregroundStyle( event.images.isEmpty ? Colors.getBase(from: colorScheme, reversed: true) : .white )
            }
            
            Spacer()
            
            makeSmallButton("pencil", label: "edit") { dismiss() }
            
            makeSmallButton("chevron.down") { dismiss() }
        }
    }
    
//    MARK: MetaDataLabel
    @ViewBuilder
    private func makeMetaDataLabel(icon: String, title: String) -> some View {
        VStack {
            HStack { Spacer() }
            
            RecallIcon(icon)
            
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
        }
        .frame(height: 30)
        .rectangularBackground(style: .secondary)
    }
    
    @ViewBuilder
    private func makeMetaData() -> some View {
        VStack {
            makeCalendarContainer()
            
            HStack {
                
                makeMetaDataLabel(icon: "tag", title: "\(event.getTagLabel())")
                
                makeMetaDataLabel(icon: "deskclock", title: "\(Int(event.getLengthInHours())) hr")
                
                makeMetaDataLabel(icon: event.isFavorite ? "checkmark" : "plus", title: "Favorite")
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
    
//    MARK: PhotoCarousel
    @ViewBuilder
    private func makePhoto(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
    }
    
    @MainActor
    @ViewBuilder
    private func makePhotoCarousel() -> some View {
        if event.images.count != 0 {
            VStack(alignment: .leading) {
                makeSectionHeader("photo.on.rectangle", title: "photos")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach( self.decodedImages, id: \.self ) { image in
                            makePhoto(uiImage: image)
                        }
                    }
                    .frame(height: 200)
                }.clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
            }
        }
    }
    
//    MARK: Map
    @ViewBuilder
    private func makeMap() -> some View {
        if let location = event.getLocationResult() {
            VStack(alignment: .leading) {
                makeSectionHeader("location", title: "\(location.title)")
                
                Map(position: $position, scope: mapNameSpace) {
                    Marker(coordinate: location.location) {
                        Text(location.title)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
                .frame(height: 250)
            }
        }
    }
    
//    MARK: Notes
    @ViewBuilder
    private func makeNotes() -> some View {
        if !event.notes.isEmpty {
            VStack(alignment: .leading) {
                makeSectionHeader("text.justify.leading", title: event.notes)
            }
        }
        
        if let url = event.getURL() {
            HStack {
                RecallIcon("link")
                Link(event.urlString, destination: url)
            }
            .foregroundStyle(.blue)
            .padding(.leading)
            .opacity(0.75)
        }
        
    }
    
//    MARK: TimeLabel
    @ViewBuilder
    private func makeTimeLabel() -> some View {
        HStack {
            RecallIcon("clock")
            
            VStack(alignment: .leading) {
                
                UniversalText( dateLabel, size: Constants.UISubHeaderTextSize, font: Constants.mainFont )
                
                UniversalText( "see more on \(dateLabel)", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                    .opacity(0.55)
            }
        }
        .padding(.leading)
    }
    
//    MARK: ActionButtons
    @ViewBuilder
    private func makeActionButton( icon: String, label: String, action: () -> Void ) -> some View {
        HStack {
            Spacer()
            
            RecallIcon( icon )
            UniversalText( label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            
            Spacer()
        }
        .rectangularBackground(style: .secondary)
    }
    
    @ViewBuilder
    private func makeActionButtons() -> some View {
        VStack(alignment: .leading) {
            
            makeSectionHeader("calendar.day.timeline.left", title: "Event Actions")
                
            makeActionButton(icon: "pencil", label: "edit") { }
            
            makeActionButton(icon: "trash", label: "delete") { }
                .foregroundStyle(.red)
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
                            .foregroundStyle(event.getColor().gradient)
                            .opacity(0.25)
                    }
                }
                .ignoresSafeArea()
                .frame(width: geo.size.width, height: geo.size.height * 0.8)
                .contentShape(Rectangle())
                
                
                let allowsScrolling = !event.images.isEmpty
                
                PhotoScrollerView (startExpanded: !allowsScrolling, allowsScrolling: allowsScrolling) {
                    VStack {
                        Spacer()
                        makeHeader()
                            .padding()
                    }
                    
                } bodyContent: {
                    VStack(alignment: .leading) {
                        
                        makeTimeLabel()
                            .padding(.bottom)
                        
                        makeNotes()
                            .padding(.bottom)

                        makeMetaData()
                            .padding(.bottom)
                        
                        Divider()
                            .padding(.bottom)
                        
                        makePhotoCarousel()
                            .padding(.bottom)
                        
                        makeMap()
                            .padding(.bottom)
                        
                        if !event.images.isEmpty || !event.locationTitle.isEmpty {
                            Divider()
                                .padding(.bottom)
                        }
                        
                        makeActionButtons()
                            .padding(.top, 20)
                            .padding(.bottom, 100)
                            
                        Spacer()
                    }
                    .padding(.vertical)
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
