//
//  CalendarEventPreviewContentView.swift
//  Recall
//
//  Created by Brian Masse on 7/29/23.
//

import Foundation
import SwiftUI

struct CalendarEventPreviewContentView: View {
    
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
    
    let event: RecallCalendarEvent
    let events: [RecallCalendarEvent]
    let width: CGFloat  //measured in pixels
    let height: CGFloat //measured in pixels
    
//    arbitrary for now
    let minWidth: CGFloat = 250
    
//    These are the pixel heights for a quart, half, and 1.5 hour events with standard spacing
//    The heights that are given to this view are in pixels, so you have to compare them to these values instead of 0.25, 0.5, and 2
    private let defaultQuarter: CGFloat = 13
    private let defaultHalf: CGFloat = 25
    private let minLength: CGFloat = 68.4
    
    @State var showingEvent: Bool = false
    
    var body: some View {
       
        ZStack {
            Rectangle()
                .foregroundColor(event.getColor())
                .cornerRadius(Constants.UIDefaultCornerRadius)
            
            VStack(alignment: .leading) {
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
        }
        .foregroundColor(.black)
        .onTapGesture { showingEvent = true }
        .if(height > defaultHalf) { view in
            view.padding(.vertical, 2)
        }
        .frame(maxHeight: height)
        .sheet(isPresented: $showingEvent) {
            CalendarEventView(event: event, events: events)
        }
        
    }
}
