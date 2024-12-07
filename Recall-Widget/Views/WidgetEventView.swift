//
//  WidgetEventView.swift
//  Recall
//
//  Created by Brian Masse on 12/14/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct WidgetEventView: View {
    
    let event: RecallWidgetCalendarEvent
    
    var timeString: String {
        let formatter = Date.FormatStyle().month(.abbreviated).day(.defaultDigits)
        
        return "\( event.startTime.formatted(formatter) )"
    }
    
//    MARK: Content
    @ViewBuilder
    private func makeContentHeader(icon: String, title: String) -> some View {
        HStack(alignment: .top) {
            RecallIcon(icon)
                .font(.callout)
            
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont, lineLimit: 1)
        }
        .opacity(0.75)
        .padding(.leading, 7)
    }
    
    @ViewBuilder
    private func makeContent() -> some View {
        
        VStack(alignment: .leading, spacing: 6) {
            
            UniversalText( event.title, size: Constants.UIHeaderTextSize - 5, font: Constants.mainFont )
            
            makeContentHeader(icon: "clock", title: timeString)
            
            makeContentHeader(icon: "tag", title: event.tag)
            
            if !event.notes.isEmpty {
                makeContentHeader(icon: "text.justify.leading",
                                  title: event.notes)
            }
        }
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
        .mask(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius - 5))
        .foregroundStyle(event.color )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 10)
    }
}


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
