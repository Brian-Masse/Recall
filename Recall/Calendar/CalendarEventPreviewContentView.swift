//
//  CalendarEventPreviewContentView.swift
//  Recall
//
//  Created by Brian Masse on 7/29/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct CalendarEventPreviewContentView: View {
    
//    MARK: View Builders
    @ViewBuilder
    private func makeMetadataTag(label: String, icon: String) -> some View {
        HStack {
            if icon != "" { ResizeableIcon(icon: icon, size: Constants.UIDefaultTextSize) }
            if label != "" { UniversalText(label, size: Constants.UIDefaultTextSize, font: Constants.titleFont, scale: true) }
        }
        .foregroundColor(.black)
    }
    
    @ViewBuilder
    private func makeMetadata(horiztonal: Bool) -> some View {
        Group {
            let timeString = "\( event.startTime.formatted( date: .omitted, time: .shortened ) ) - \( event.endTime.formatted( date: .omitted, time: .shortened ) )"
            
            if event.isTemplate {
                makeMetadataTag(label: "", icon: "doc.plaintext")
                if horiztonal { Spacer() }
            }
            makeMetadataTag(label: "\(event.category?.label ?? "no tag")", icon: "tag")
            if horiztonal { Spacer() }
            makeMetadataTag(label: timeString, icon: "")
        }
    }
    
//    MARK: Vars
    
    @Environment(\.colorScheme) var colorScheme
    
    let event: RecallCalendarEvent
    let events: [RecallCalendarEvent]
    let width: CGFloat  //measured in pixels
    let height: CGFloat //measured in pixels
    let allowTapGesture: Bool
    
    @ObservedRealmObject var index = RecallModel.index
    
//    arbitrary for now
    let minWidth: CGFloat = 250
    
//    These are the pixel heights for a quart, half, and 1.5 hour events with standard spacing
//    The heights that are given to this view are in pixels, so you have to compare them to these values instead of 0.25, 0.5, and 2
    private let defaultQuarter: CGFloat = 13
    private let defaultHalf: CGFloat = 25
    private let minLength: CGFloat = 68.4
    private let minDescriptionLength: CGFloat = 75
    
    @Binding var selecting: Bool
    @Binding var selection: [RecallCalendarEvent]
    
    @State var showingEvent: Bool = false
    
    init( event: RecallCalendarEvent, events: [RecallCalendarEvent], width: CGFloat, height: CGFloat, selecting: Binding<Bool>? = nil, selection: Binding<[RecallCalendarEvent]>? = nil, allowTapGesture: Bool = false) {
        
        self.event = event
        self.events = events
        self.width = width
        self.height = height
        self.allowTapGesture = allowTapGesture
        
        self._selecting = (selecting == nil) ? Binding(get: { false }, set: { _ in }) : selecting!
        self._selection = (selection == nil) ? Binding(get: { [] }, set: { _ in }) : selection!
    }
    
    private func selected() -> Bool {
        let index = selection.firstIndex(of: event)
        return index != nil
    }
    
//    MARK: Body
    var body: some View {
       
        ZStack {
            Rectangle()
                .foregroundColor(event.getColor())
                .cornerRadius(Constants.UIDefaultCornerRadius)
            
            VStack(alignment: .leading) {
//                MARK: Title
                HStack {
                    UniversalText( event.title, size: Constants.UITitleTextSize, font: Constants.titleFont, true, scale: true)
                    
                    Spacer()
                    
                    if width > minWidth && height > defaultHalf {
                        Image(systemName: "arrow.up")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxHeight: Constants.UIHeaderTextSize)
                    }
                }
                
//                MARK: Content
                if height > minDescriptionLength && index.showNotesOnPreview {
                    UniversalText( event.notes, size: Constants.UISmallTextSize, font: Constants.mainFont ).opacity(0.8)
                }
                
                if height > minLength {
                    
                    Spacer()
                    if width > minWidth {
                        HStack { makeMetadata(horiztonal: true) }
                    } else {
                        VStack(alignment: .leading) { makeMetadata(horiztonal: false) }
                    }
                }
            }
            .padding(.horizontal)
            .if(height > defaultQuarter) { view in
                view.padding(.vertical, 5)
            }
            
//            this handles the event appearance when the user is selecting a group of events to edit
           if selecting && !selected() {
               Rectangle()
                   .foregroundStyle(colorScheme == .dark ? .black : .white)
                   .opacity(0.7)
                   .cornerRadius(Constants.UIDefaultCornerRadius)
           }
        }
        .foregroundColor(.black)
        .if(height > defaultHalf) { view in
            view.padding(.vertical, 2)
        }
        .if(allowTapGesture) { view in
            view.onTapGesture { showingEvent = true }
        }
        .frame(maxHeight: height)
        .sheet(isPresented: $showingEvent) {
            CalendarEventView(event: event, events: events)
        }
        
    }
}
