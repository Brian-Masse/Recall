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
    @ObservedObject private var viewModel: RecallCalendarContainerViewModel = RecallCalendarContainerViewModel.shared
    
    let event: RecallCalendarEvent
    let events: [RecallCalendarEvent]
    
    let showMetaData: Bool

    
//   These are all relativley arbitrary values, but they've been found to work across a number of device sizes and text scales
    private let minHeight: CGFloat = 65
    private let minHeightForDescription: CGFloat = 110
    private let minHeightForTitle: Double = 15
    
    @State var showingEvent: Bool = false
    
    let height: Double
    
    init( event: RecallCalendarEvent, events: [RecallCalendarEvent], showMetaData: Bool = true, height: Double = .infinity) {
        
        self.event = event
        self.events = events
        self.showMetaData = showMetaData
        self.height = height
    }
    
    private var isSelected: Bool {
        let index = viewModel.selection.firstIndex(of: event)
        return index != nil
    }
    
    
    @ViewBuilder
    private func makeTitle() -> some View {
        if height > minHeightForTitle {
            UniversalText( event.title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
        }
    }
    
    @ViewBuilder
    private func makeNode(icon: String, text: String, wrap: Bool = false) -> some View {
        HStack {
            RecallIcon(icon)
                .font(.caption)
            
            UniversalText( text, size: Constants.UISmallTextSize, font: Constants.mainFont, wrap: wrap )
        }
        .opacity(0.65)
    }
    
//    MARK: content
    @ViewBuilder
    private func makeBody() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {Spacer()}
            
            makeTitle()
            
            if height > minHeight {
                if !event.notes.isEmpty && RecallModel.index.showNotesOnPreview {
                    makeNode(icon: "text.justify.leading", text: event.notes, wrap: true)
                        .padding(.bottom, 7)
                }
                
                if showMetaData {
                    let timeString = "\( event.startTime.formatted( date: .omitted, time: .shortened ) ) - \( event.endTime.formatted( date: .omitted, time: .shortened ) )"
                    
                    makeNode(icon: "clock", text: timeString)

                    makeNode(icon: "tag", text: event.getTagLabel())

                    if let urlString = event.getURL()?.relativePath {
                        makeNode(icon: "link", text: urlString)
                    }

                    if let locationTitle = event.getLocationResult()?.title {
                        makeNode(icon: "location", text: locationTitle)
                    }

                    if !event.images.isEmpty {
                        makeNode(icon: "photo.on.rectangle", text: "has Photos")
                    }
                }
            }
            Spacer()
        }
        .foregroundStyle(event.getColor().safeMix(with: .black, by: colorScheme == .light ? 0.5 : 0) )
    }
    
    private func verticalPadding() -> Double {
        min( 12, (height - Constants.UISubHeaderTextSize) / 2 )
    }
    
//    MARK: Body
    var body: some View {
        
        ZStack {
            Rectangle()
                .opacity(0.25)
                .background()
            
//            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius - 5)
//                .stroke(style: .init(lineWidth: 2))
//                .opacity(0.5)
            
            makeBody()
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                        .foregroundColor(event.getColor())
                        .frame(width: 5)
                        .offset(x: -15)
                }
                .padding(.leading, 10)
                .padding(.horizontal, 12)
                .padding(.vertical, verticalPadding())
                .frame(maxHeight: height, alignment: .top)
            
            if viewModel.selecting && !isSelected {
                Rectangle()
                    .opacity(0.25)
                    .foregroundStyle(colorScheme == .light ? .white : .black)
            }
                
        }
        .foregroundStyle(event.getColor() )
        .mask(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius - 5))
    }
}
