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

//TODO: Fix Favorites Page

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


//MARK: RecallCalendarEventView
struct RecallCalendarEventView: View {
     
    @ObservedObject private var calendarViewModel = RecallCalendarContainerViewModel.shared
    @ObservedObject private var imageStoreViewModel = RecallCalendarEventImageStore.shared
    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
    @Environment( \.colorScheme ) var colorScheme
    
//    MARK: Vars
    @ObservedRealmObject var event: RecallCalendarEvent
    let events: [RecallCalendarEvent]
    
    @State private var showEditView: Bool = false
    @State private var showDeleteAlert: Bool = false
    
    @State private var decodedImages: [UIImage] = []
    
    @State private var position: MapCameraPosition
    @Namespace private var mapNameSpace
    
    private let eventTitleMinLength: Int = 24
    
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
        let decodedImages = await imageStoreViewModel.decodeImages(for: event, expectedCount: event.images.count)
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
        let formatter = Date.FormatStyle().month().day().year()
        return event.startTime.formatted(formatter)
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
            
            DismissButton()
        }
        .foregroundStyle( event.images.isEmpty ? titleColor : .white )
    }
    
//    MARK: MetaData
    @ViewBuilder
    private func makeMetaData() -> some View {
        VStack {
            HStack {
                
                makeMetaDataLabel(icon: event.isFavorite ? "checkmark" : "plus", title: "Favorite") {
                    event.toggleFavorite()
                }
                
                makeMetaDataLabel(icon: "tag", title: "\(event.getTagLabel())")
                
                makeMetaDataLabel(icon: "deskclock", title: event.getDurationString())
                
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
                         includeGestures: false,
                         highlightEvent: event)
                .padding(.leading, 25 )
                .task { await calendarViewModel.loadEvents(for: event.startTime, in: events) }
        }
        .frame(height: 150)
        .rectangularBackground(style: .secondary, stroke: true)
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
            makeSectionHeader("photo.on.rectangle",
                              title: "photos",
                              fillerMessage: "Add photos",
                              isActive: event.images.count != 0) {
                showEditView = true
            }
            
            if event.images.count != 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach( self.decodedImages, id: \.self ) { image in
                            makePhoto(uiImage: image)
                        }
                    }
                    .frame(height: event.images.count == 1 ? 300 : 200)
                }
                .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
                .padding(.bottom)
            }
        }
    }
    
//    MARK: Map
    @ViewBuilder
    private func makeMap() -> some View {
        VStack(alignment: .leading) {
            makeSectionHeader("location",
                              title: event.locationTitle,
                              fillerMessage: "Add a location",
                              isActive: !event.locationTitle.isEmpty) {
                showEditView = true
            }
            
            if let location = event.getLocationResult() {
                
                Map(position: $position, scope: mapNameSpace) {
                    Marker(coordinate: location.location) {
                        Text(location.title)
                    }
                }
                .allowsHitTesting(false)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
                .frame(height: 200)
                .padding(.bottom)
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
                .opacity(0.75)
            
            VStack(alignment: .leading) {
                
                UniversalText( timeLabel, size: Constants.UISubHeaderTextSize, font: Constants.mainFont )
                
                HStack {
                    
                    RecallIcon("chevron.left")
                        .font(.caption)
                    
                    UniversalText( "see more on \(dateLabel)", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                    
                    RecallIcon("chevron.right")
                        .font(.caption)
                }
                .opacity(0.55)
            }
            
            Spacer()
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
            
            makeActionButton(icon: "circle.rectangle.filled.pattern.diagonalline", label: "favorite") { event.toggleFavorite() }
            
            makeActionButton(icon: "pencil", label: "edit") { showEditView = true }
            
            makeActionButton(icon: "trash", label: "delete") { showDeleteAlert = true }
                .foregroundStyle(.red)
        }
        .padding(.bottom, 50)
    }
    
//    MARK: LargePhotoCarousel
    @State private var photoCarouselIndex: Int = 0
    
    @available(iOS 18.0, *)
    @ViewBuilder
    private func makeLargePhotoCarousel(in geo: GeometryProxy) -> some View {
        if self.decodedImages.count > 0 {
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach( self.decodedImages, id: \.self ) { image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width)
                            .clipped()
                    }
                }.scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .onScrollGeometryChange(for: Double.self, of: { geo in geo.contentOffset.x }) { oldValue, newValue in
                self.photoCarouselIndex = Int(floor((newValue - (geo.size.width / 2)) / geo.size.width)) + 1
            }
            .overlay(alignment: .top) {
                makePhotoCarouselIndex()
                    .padding(.top, 65)
            }
        }
    }
    
    @ViewBuilder
    private func makePhotoCarouselIndex() -> some View {
        if self.decodedImages.count > 1 {
            HStack {
                
                ForEach( 0..<decodedImages.count, id: \.self ) { i in
                    Group {
                        if i != 0 {
                            Circle()
                                .frame(width: 7, height: 7)
                        } else {
                            RecallIcon( "square.grid.2x2.fill" )
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.white)
                    .opacity( i == photoCarouselIndex ? 1 : 0.5 )
                }
            }
        }
    }
    
    private struct NullContentShape: Shape {
        func path(in rect: CGRect) -> Path {
            var rectCopy = rect
            rectCopy.size.height = 0
            
            return Path(rectCopy)
        }
    }
    
//    MARK: Background
    @ViewBuilder
    private func makeBackground() -> some View {
        GeometryReader { geo in
            if let image = self.decodedImages.first {
                Group {
                    if #available(iOS 18, *) {
                        makeLargePhotoCarousel(in: geo)
                    } else {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .overlay {
                    LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .init(x: 0.5, y: 0.7))
                        .allowsHitTesting(false)
                        .contentShape(NullContentShape())
                }
                .ignoresSafeArea()
                .frame(width: geo.size.width, height: geo.size.height * 0.5)
            } else {
                Rectangle()
                    .foregroundStyle(event.getColor().gradient)
                    .ignoresSafeArea()
            }
        }
    }
    
//    MARK: Content
    @ViewBuilder
    private func makeContent() -> some View {
        VStack(spacing: 7) {
            VStack(alignment: .leading) {
                if event.title.count > eventTitleMinLength {
                    makeSectionHeader("widget.small", title: event.title)
                        .padding(.bottom)
                }
                
                makeTimeLabel()
                    .padding(.bottom)
                
                makeNotes()
                    .padding(.bottom)
                
                makeMetaData()
                    .padding(.bottom)
            }
            .padding(.top)
            .rectangularBackground(style: .primary)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: Constants.UILargeCornerRadius,
                                              topTrailingRadius: Constants.UILargeCornerRadius))
            
            makeRichDataSection()
                .rectangularBackground(style: .primary)
            
            VStack {
                makeActionButtons()
                
                Spacer()
            }
            .rectangularBackground(style: .primary)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: Constants.UILargeCornerRadius,
                                              bottomTrailingRadius: Constants.UILargeCornerRadius))
        }
    }
    
    @ViewBuilder
    private func makeRichDataSection() -> some View {
        VStack(alignment: .leading) {
            if !event.images.isEmpty || !event.locationTitle.isEmpty {
                makePhotoCarousel()
                
                makeMap()
            } else {
                
                makeSectionHeader("grid", title: "Additional Information")
                    .padding(.top)
                
                HStack {
                    makePhotoCarousel()
                    makeMap()
                }
            }
        }
    }
    
//    MARK: PhotoScroller
    @available(iOS 18, *)
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
            
            if #available(iOS 18, *) {
                makePhotoScroller()
                    .padding(5)
            } else {
                makeRegularLayout()
                    .padding(5)
            }
        }
        .background(.black)
        .task { await onAppear() }
        .ignoresSafeArea(edges: .bottom)
        
        .onChange(of: event.images) { Task { await onAppear() } }
        .onChange(of: showEditView) {
            if showEditView { coordinator.presentSheet(.eventEdittingView(event: event)) }
            showEditView = false
        }
        
        .deleteableCalendarEvent(deletionBool: $showDeleteAlert, event: event)
        
        .animation(.easeInOut, value: event)
    }
}

//
//#Preview {
//    RecallCalendarEventView(event: sampleEventNoPhotos )
//}
