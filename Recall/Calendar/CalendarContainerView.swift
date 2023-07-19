//
//  CalendarContinerView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI

struct CalendarContainer: View {
    
    private struct CalendarView: View {
        private func makeHourLabel( from hour: Int ) -> String {
            if hour == 0 { return "12AM" }
            if hour < 12 { return "\(hour)AM" }
            if hour == 12 { return "12PM" }
            if hour > 12 { return "\(hour - 12)PM" }
            return ""
        }
        
        let hoursToDisplay: CGFloat
        let spacing: CGFloat
        
        var body: some View {
            ForEach(0..<Int(hoursToDisplay), id: \.self) { hr in
                VStack {
                    HStack(alignment: .top) {
                        UniversalText( makeHourLabel(from: hr).uppercased(), size: Constants.UISmallTextSize, lighter: true  )
                        
                        Rectangle()
                            .frame(height: 1)
                            .universalTextStyle()
                    }
                    .offset(y: CGFloat(hr) * spacing )
                    Spacer()
                }
            }
        }
    }
    
    let geo: GeometryProxy
    let components: [RecallCalendarEvent]
    
    @Binding var dragging: Bool
    
    var body: some View {
   
        let height = geo.size.height * 2
        let hoursToDisplay:CGFloat = 24
        let spacing = height / hoursToDisplay
        
        ZStack(alignment: .top) {
            CalendarView(hoursToDisplay: hoursToDisplay, spacing: spacing)
            
            ForEach( components, id: \.self ) { component in
                CalendarEventPreviewView(component: component, spacing: spacing, dragging: $dragging)
            }
            .padding(.horizontal)
            .padding(.leading)
        }
        .frame(height: height)
    }
}
