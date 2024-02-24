//
//  CalendarEventPreviewContentView.swift
//  Recall
//
//  Created by Brian Masse on 7/29/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

struct CalendarEventPreviewContentView: View {
    
//    MARK: View Builders
    @ViewBuilder
    private func makeMetadataTag(label: String, icon: String) -> some View {
        HStack {
            if icon != "" { ResizableIcon(icon, size: Constants.UIDefaultTextSize) }
            if label != "" { UniversalText(label, size: Constants.UISmallTextSize, font: Constants.titleFont, scale: true) }
        }
        .foregroundColor(.black)
    }
    
    @ViewBuilder
    private func makeMetadata(addHorizontalSpacing: Bool) -> some View {
        let timeString = "\( event.startTime.formatted( date: .omitted, time: .shortened ) ) - \( event.endTime.formatted( date: .omitted, time: .shortened ) )"
        
        if event.isTemplate {
            makeMetadataTag(label: "", icon: "doc.plaintext")
            if addHorizontalSpacing { Spacer() }
        }
        makeMetadataTag(label: "\(event.category?.label ?? "no tag")", icon: "tag")
        if addHorizontalSpacing { Spacer() }
        makeMetadataTag(label: timeString, icon: "")
    }

    @ViewBuilder
    private func makeBody() -> some View {
        UniversalText( event.title,
                       size: Constants.UISubHeaderTextSize,
                       font: Constants.titleFont,
                       scale: true,
                       minimumScaleFactor: 0.5)
        
        if height > minHeightForDescription && index.showNotesOnPreview && !event.notes.isEmpty {
            UniversalText( event.notes,
                           size: Constants.UISmallTextSize,
                           font: Constants.mainFont )
            .opacity(0.8)
        }
    }
    
//    MARK: Layouts
    @ViewBuilder
    private func makeFullLayout() -> some View {
        VStack(alignment: .leading) {
            makeBody()
            
            Spacer()
            
            if width < minWidth { makeMetadata(addHorizontalSpacing: false) }
            else { HStack { makeMetadata(addHorizontalSpacing: true) } }
        }
        .padding(.bottom, 5)
        .padding(.top, 2)
    }
    
    @ViewBuilder
    private func makeShortLayout() -> some View {
        Spacer()
        UniversalText( event.title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont, scale: true, minimumScaleFactor: 0.1)
            .padding(.vertical, -3)
        Spacer()
    }
    
//    MARK: Vars
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var containerModel: CalendarContainerModel
    
    let event: RecallCalendarEvent
    let events: [RecallCalendarEvent]
    let width: CGFloat  //measured in pixels
    let height: CGFloat //measured in pixels
    let allowTapGesture: Bool
    
    @ObservedRealmObject var index = RecallModel.index
    
//   These are all relativley arbitrary values, but they've been found to work across a number of device sizes and text scales
    let minWidth: CGFloat = 250
    private let minHeight: CGFloat = 60
    private let minHeightForDescription: CGFloat = 68
    
    @State var showingEvent: Bool = false
    
    init( event: RecallCalendarEvent, events: [RecallCalendarEvent], width: CGFloat, height: CGFloat, allowTapGesture: Bool = false) {
        
        self.event = event
        self.events = events
        self.width = width
        self.height = height
        self.allowTapGesture = allowTapGesture
    }
    
    private func selected() -> Bool {
        let index = containerModel.selection.firstIndex(of: event)
        return index != nil
    }
    
//    MARK: Body
    var body: some View {
        
        ZStack {
            Rectangle()
                .foregroundColor(event.getColor())
                .cornerRadius(Constants.UIDefaultCornerRadius)
            
            VStack(alignment: .leading) {
                HStack {Spacer()}
                
                if height < minHeight { makeShortLayout() }
                else { makeFullLayout() }
                
            }
            .padding(.horizontal)
            
            if containerModel.selecting && !selected() {
                Rectangle()
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .opacity(0.7)
                    .cornerRadius(Constants.UIDefaultCornerRadius)
            }
        }
        .foregroundColor(.black)
        .padding(.vertical, 2)
        .if(allowTapGesture) { view in view.onTapGesture { showingEvent = true } }
        .frame(maxHeight: height)
        .sheet(isPresented: $showingEvent) {
            CalendarEventView(event: event, events: events)
        }
        
    }
}
