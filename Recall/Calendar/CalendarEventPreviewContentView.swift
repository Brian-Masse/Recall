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
            if label != "" { UniversalText(label, size: Constants.UIDefaultTextSize, font: Constants.titleFont) }
        }
        .foregroundColor(.black)
    }
    
    @ViewBuilder
    private func makeMetadata(horiztonal: Bool) -> some View {
        Group {
            let timeString = "\( event.startTime.formatted( .dateTime.hour() ) ) - \( event.endTime.formatted( .dateTime.hour() ) )"
            
            makeMetadataTag(label: "", icon: "doc.plaintext")
            if horiztonal { Spacer() }
            makeMetadataTag(label: "\(event.category?.label ?? "no tag")", icon: "tag")
            if horiztonal { Spacer() }
            makeMetadataTag(label: timeString, icon: "")
        }
    }
    
    let event: RecallCalendarEvent
    let width: CGFloat  //measured in pixels
    let height: CGFloat //measured in hours
    
//    arbitrary for now
    let minWidth: CGFloat = 250
    let minLength: CGFloat = 2
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                UniversalText( event.title, size: Constants.UITitleTextSize, font: Constants.titleFont, true, scale: true)
                Spacer()
                if width > minWidth { ResizeableIcon(icon: "arrow.up", size: Constants.UIHeaderTextSize).padding(.trailing, 5) }
            }
            .padding(.horizontal)
            .padding([.vertical], 5)
            
            Spacer()
        
            Group {
                if height > minLength {
                    if width > minWidth {
                        HStack { makeMetadata(horiztonal: true) }
                    } else {
                        VStack(alignment: .leading) { makeMetadata(horiztonal: false) }
                    }
                }
                
            }.padding([.horizontal, .bottom])
        }
        .foregroundColor(.black)
        .background(event.getColor())
        .cornerRadius(Constants.UIDefaultCornerRadius)
    }
}