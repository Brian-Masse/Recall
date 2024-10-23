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
    
//    MARK: Vars
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var viewModel: RecallCalendarViewModel = RecallCalendarViewModel.shared
    
    let event: RecallCalendarEvent
    let events: [RecallCalendarEvent]
    let allowTapGesture: Bool
    
//   These are all relativley arbitrary values, but they've been found to work across a number of device sizes and text scales
    let minWidth: CGFloat = 250
    private let minHeight: CGFloat = 65
    private let minHeightForDescription: CGFloat = 110
    private let minHeightForTitle: Double = 15
    
    @State var showingEvent: Bool = false
    
    init( event: RecallCalendarEvent, events: [RecallCalendarEvent], allowTapGesture: Bool = false, forDisplay: Bool = false) {
        
        self.event = event
        self.events = events
        self.allowTapGesture = allowTapGesture
    }
    
    private var isSelected: Bool {
        let index = viewModel.selection.firstIndex(of: event)
        return index != nil
    }
    
//    MARK: Title
    @ViewBuilder
    private func makeTitle(in geo: GeometryProxy) -> some View {
        if geo.size.height > minHeightForTitle {
            let shouldScale = geo.size.height < Constants.UISubHeaderTextSize + 5
            
            UniversalText( event.title,
                           size: Constants.UISubHeaderTextSize,
                           font: Constants.titleFont,
                           scale: shouldScale,
                           minimumScaleFactor: 0.1)
        }
    }
    
    
    @ViewBuilder
    private func makeNode(icon: String, text: String) -> some View {
        HStack {
            RecallIcon(icon)
                .font(.caption)
            
            UniversalText( text, size: Constants.UISmallTextSize, font: Constants.mainFont, wrap: false )
        }
        .opacity(0.65)

    }
    
//    MARK: content
    @ViewBuilder
    private func makeBody(in geo: GeometryProxy) -> some View {
        let timeString = "\( event.startTime.formatted( date: .omitted, time: .shortened ) ) - \( event.endTime.formatted( date: .omitted, time: .shortened ) )"
        
        VStack(alignment: .leading, spacing: 0) {
            HStack {Spacer()}
            
            makeTitle(in: geo)
            
            if geo.size.height > minHeight {
                if let _ = event.getURL() {
                    makeNode(icon: "link", text: event.urlString)
                }
                
                makeNode(icon: "clock", text: timeString)
            
                makeNode(icon: "tag", text: event.getTagLabel())
                
            }
            
            Spacer()
            
            if geo.size.height > minHeightForDescription && /*index.showNotesOnPreview &&*/ !event.notes.isEmpty {
                UniversalText( event.notes,
                               size: Constants.UISmallTextSize,
                               font: Constants.mainFont)
                .opacity(0.75)
            }
        }
        .foregroundStyle(event.getColor().safeMix(with: .black, by: colorScheme == .light ? 0.5 : 0) )
    }
    
    private func verticalPadding(in geo: GeometryProxy) -> Double {
        min( 12, (geo.size.height - Constants.UISubHeaderTextSize) / 2 )
    }
    
//    MARK: Body
    var body: some View {
        
        GeometryReader { geo in
            Rectangle()
                .foregroundStyle(.background)
            
            Rectangle()
                .opacity(0.25)
                .opacity(viewModel.selecting && !isSelected ? 0.3 : 1)
            
            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius - 5)
                .stroke(style: .init(lineWidth: 2))
                .opacity(0.5)
            
            makeBody(in: geo)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                        .foregroundColor(event.getColor())
                        .frame(width: 5)
                        .offset(x: -15)
                }
                .padding(.leading, 10)
                .padding(.horizontal, 12)
                .padding(.vertical, verticalPadding(in: geo))
        }
        .foregroundStyle(event.getColor() )
        .mask(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius - 5))
        .if(allowTapGesture) { view in view.onTapGesture { showingEvent = true } }
        .sheet(isPresented: $showingEvent) {
            CalendarEventView(event: event, events: events)
        }
    }
}
