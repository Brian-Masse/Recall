//
//  CalendarTemplatesPageView.swift
//  Recall
//
//  Created by Brian Masse on 8/16/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct TemplatesPageView: View {
    
    struct TemplatePreview: View {
        let template: RecallCalendarEvent
        let events: [RecallCalendarEvent]
        
        @State var showingEvent: Bool = false
        
        var body: some View {
            VStack(alignment: .leading) {
            
                HStack {
//                    Image(systemName: "calendar.day.timeline.leading")
//                        .foregroundColor(template.getColor())
                    UniversalText( template.title, size: Constants.UISubHeaderTextSize, font: Constants.mainFont )

                    Spacer()
                    
                    let dateText = "\(template.startTime.formatted(date: .omitted, time: .shortened)) - \(template.endTime.formatted(date: .omitted, time: .shortened))"
                    UniversalText( dateText, size: Constants.UISmallTextSize, font: Constants.mainFont )
                }
                
                CalendarEventView.makeOverviewView(from: template, in: events)
                
            }
            .padding(5)
            .onTapGesture { showingEvent = true }
            .sheet(isPresented: $showingEvent) { CalendarEventView(event: template, events: events) }
            .background( template.getColor() )
        }
    }
    
    let events: [RecallCalendarEvent]
    
    @MainActor
    var body: some View {
        
        let templates = RecallModel.getTemplates(from: events)
        
        VStack(alignment: .leading) {

            UniversalText( "Templates", size: Constants.UITitleTextSize, font: Constants.titleFont )
                .padding(.bottom)

            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    GeometryReader { geo in
                    
                        ForEach( templates ) { template in
                            
                            //                        TemplatePreview(template: template, events: events)
                            
                            CalendarEventPreviewContentView(event: template, width: geo.size.width, height: 200)
                            
                            if template.title != templates.last?.title ?? "" {
                                Rectangle()
                                    .universalTextStyle()
                                    .opacity(0.5)
                                    .frame(height: 1)
                            }
                        }
                    }.frame(height: 200)
                }
                .opaqueRectangularBackground(7, stroke: true)
                .padding(.bottom, Constants.UIBottomOfPagePadding)
            }
        }
        .padding()
        .universalBackground()
        
    }
    
}
