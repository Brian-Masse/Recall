//
//  WidgetEventView.swift
//  Recall
//
//  Created by Brian Masse on 12/14/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: WidgetEventView
struct WidgetEventView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let event: RecallWidgetCalendarEvent
    let height: Double
    let showContent: Bool
    
    private let minimiumHeightForContent: Double = 50
    
    init( event: RecallWidgetCalendarEvent, height: Double = .infinity, showContent: Bool = true ) {
        self.event = event
        self.height = height
        self.showContent = showContent
    }
    
    var timeString: String {
        let formatter = Date.FormatStyle().month(.abbreviated).day(.defaultDigits)
        
        return "\( event.startTime.formatted(formatter) )"
    }
    
//    MARK: Content
    @ViewBuilder
    private func makeContentHeader(icon: String, title: String, lineLimit: Int = 1) -> some View {
        HStack(alignment: .top) {
            RecallIcon(icon)
                .font(.caption)
            
            UniversalText(title, size: Constants.UISmallTextSize, font: Constants.mainFont, lineLimit: lineLimit)
        }
        .opacity(0.75)
    }
    
    @ViewBuilder
    private func makeContent() -> some View {
        
        VStack(alignment: .leading, spacing: 3) {
            
            UniversalText( event.title, size: Constants.UISubHeaderTextSize, font: Constants.mainFont, lineLimit: 3 )
            
            if showContent && height > minimiumHeightForContent {
                makeContentHeader(icon: "clock", title: timeString)
                
                makeContentHeader(icon: "tag", title: event.tag)
                
                if !event.notes.isEmpty {
                    makeContentHeader(icon: "text.justify.leading",
                                      title: event.notes,
                                      lineLimit: 4)
                }
            }
        }
        .foregroundStyle( event.color.safeMix(with: colorScheme == .light ? .black : .white,
                                              by: 0.2) )
    }
    
    
    
//    MARK: Body
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .opacity(0.25)
                .background()
            
            Rectangle()
                .frame(width: 5)
                .cornerRadius(100)
                .padding(10)
            
            makeContent()
                .padding(7)
                .padding(.leading)
        }
        .frame(maxHeight: height, alignment: .top)
        .mask(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius - 6))
        .foregroundStyle(event.color )
    }
}

//MARK: WidgetPlaceholderView
struct WidgetPlaceholderView: View {
    
    let icon: String
    let message: String
    let subtext: String
    
    var body: some View {
        VStack {
            HStack {Spacer()}
            Spacer()
            RecallIcon(icon)
                .font(.title)
                .padding(.bottom, 5)
            
            UniversalText(message, size: Constants.UISubHeaderTextSize + 3, font: Constants.mainFont)
            
            UniversalText(subtext, size: Constants.UISmallTextSize, font: Constants.mainFont, textAlignment: .center)
                .opacity(0.65)
            Spacer()
        }
    }
}

//MARK: Preview
#Preview {
    let event: RecallWidgetCalendarEvent = .init(title: "title",
                                                 notes: "notes notes note snotesnotes",
                                                 startTime: .now,
                                                 endTime: .now + Constants.HourTime * 2,
                                                 color: .blue)
//
    WidgetEventView(event: event)
        .frame(width: 300, height: 300)
        .border(.red)
}
