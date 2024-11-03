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
    @State var event: RecallCalendarEvent
    let events: [RecallCalendarEvent]
    
    @State private var showEditView: Bool = false
    @State private var showDeleteAlert: Bool = false
    
    @State private var decodedImages: [UIImage] = []
    
    @State private var position: MapCameraPosition
    @Namespace private var mapNameSpace
    
    private let largeCornerRadius: Double = 58
    
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
    
//    MARK: Labels
    private var timeLabel: String {
        let formatter = Date.FormatStyle().hour().minute()
        let str1 = event.startTime.formatted(formatter)
        let str2 = event.endTime.formatted(formatter)
        
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
    
    @ViewBuilder
    private func makeSectionFiller(message: String) -> some View {
        UniversalButton {
            VStack {
                HStack { Spacer() }
                
                RecallIcon( "plus" )
                
                UniversalText( message, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            }
            .rectangularBackground(style: .secondary)
            
        } action: { showEditView = true }
    }
    
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        
        let titleColor = event.getColor().safeMix(with: .black, by: 0.6)
        
        HStack(spacing: 10) {
            VStack(alignment: .leading) {
                UniversalText( event.title, size: Constants.UIHeaderTextSize, font: Constants.titleFont, lineLimit: 2 )
            }
            
            Spacer()
            
            makeSmallButton("pencil", label: "edit") { showEditView = true }
            
            makeSmallButton("chevron.down") { dismiss() }
        }.foregroundStyle( event.images.isEmpty ? titleColor : .white )
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
            HStack {
                
                makeMetaDataLabel(icon: "tag", title: "\(event.getTagLabel())")
                
                makeMetaDataLabel(icon: "deskclock", title: "\(Int(event.getLengthInHours())) hr")
                
                makeMetaDataLabel(icon: event.isFavorite ? "checkmark" : "plus", title: "Favorite")
            }
            
            makeCalendarContainer()
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
        VStack(alignment: .leading) {
            makeSectionHeader("photo.on.rectangle", title: "photos")
            
            if event.images.count != 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach( self.decodedImages, id: \.self ) { image in
                            makePhoto(uiImage: image)
                        }
                    }
                    .frame(height: 200)
                }.clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
            } else {
                
                makeSectionFiller(message: "Add photos for this event")
            }
        }
    }
    
//    MARK: Map
    @ViewBuilder
    private func makeMap() -> some View {
        VStack(alignment: .leading) {
            if let location = event.getLocationResult() {
                
                makeSectionHeader("location", title: "\(location.title)")
                
                Map(position: $position, scope: mapNameSpace) {
                    Marker(coordinate: location.location) {
                        Text(location.title)
                    }
                }
                .allowsHitTesting(false)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
                .frame(height: 200)
                
            } else {
                makeSectionHeader("location", title: "location")
                
                makeSectionFiller(message: "Add a location for this event")
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
    private func makeActionButton( icon: String, label: String, action: @escaping () -> Void ) -> some View {
        UniversalButton {
            HStack {
                Spacer()
                
                RecallIcon( icon )
                UniversalText( label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                
                Spacer()
            } .rectangularBackground(style: .secondary)
        } action: { action() }
    }
    
    @ViewBuilder
    private func makeActionButtons() -> some View {
        VStack(alignment: .leading) {
            
            makeSectionHeader("calendar.day.timeline.left", title: "Event Actions")
            
            makeActionButton(icon: "circle.rectangle.filled.pattern.diagonalline", label: "favorite") { }
            
            makeActionButton(icon: "pencil", label: "edit") { showEditView = true }
            
            makeActionButton(icon: "trash", label: "delete") { showDeleteAlert = true }
                .foregroundStyle(.red)
        }
        .padding(.bottom, 50)
    }
    
//    MARK: Background
    @ViewBuilder
    private func makeBackground() -> some View {
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
                    }
                }
                .overlay {
                    LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .init(x: 0.5, y: 0.7))
                }
                .ignoresSafeArea()
                .frame(width: geo.size.width, height: geo.size.height * 0.8)
                .contentShape(Rectangle())
            }
        }
    }
    
//    MARK: Content
    @ViewBuilder
    private func makeContent() -> some View {
        VStack(spacing: 7) {
            VStack(alignment: .leading) {
                makeTimeLabel()
                    .padding(.bottom)
                
                makeNotes()
                    .padding(.bottom)
                
                makeMetaData()
                    .padding(.bottom)
            }.rectangularBackground(style: .primary)
            
            VStack {
                makePhotoCarousel()
                    .padding(.bottom)
                
                makeMap()
                    .padding(.bottom)
            }.rectangularBackground(style: .primary)
                
            VStack {
                makeActionButtons()
                
                Spacer()
            }.rectangularBackground(style: .primary)
        }
        .clipShape(RoundedRectangle(cornerRadius: largeCornerRadius))
        .padding(.horizontal, 5)
        .padding(.bottom, 20)
    }
    
//    MARK: PhotoScroller
    @available(iOS 18.0, *)
    @ViewBuilder
    private func makePhotoScroller() -> some View {
                
        let allowsScrolling = !event.images.isEmpty
        
        PhotoScrollerView (startExpanded: !allowsScrolling, allowsScrolling: allowsScrolling) {
            VStack {
                Spacer()
                makeHeader()
                    .padding()
            }
            
        } bodyContent: { makeContent() }
    }
    
//    MARK: RegularLayout
    @ViewBuilder
    private func makeRegularLayout() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            makeHeader()
                .frame(height: 450, alignment: .bottom)
            
            makeContent()
        }
    }
    
    
//    MARK: Body
    var body: some View {
        ZStack(alignment: .top) {
            makeBackground()
            
            if #available(iOS 18.0, *) {
                makePhotoScroller()
            } else {
                makeRegularLayout()
            }
        }
        .task { await onAppear() }
        .background(.black)
        .deleteableCalendarEvent(deletionBool: $showDeleteAlert, event: event)
        .sheet(isPresented: $showEditView) {
            CalendarEventCreationView.makeEventCreationView(currentDay: event.startTime,
                                                            editing: true,
                                                            event: event)
        }
    }
}


#Preview {
    TestCalendarEventView(event: sampleEvent )
}
