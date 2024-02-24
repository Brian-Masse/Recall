//
//  CalendarView.swift
//  Recall
//
//  Created by Brian Masse on 7/29/23.
//

import Foundation
import SwiftUI
import UIUniversals

struct CalendarView: View {
    
    @ViewBuilder
    func makeTimeMarker(hour: CGFloat, label: String, color: Color) -> some View {
        VStack {
            HStack(alignment: .top) {
                UniversalText( label, size: Constants.UISmallTextSize, font: Constants.mainFont  )
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(color)
            }
            .id( Int(hour.rounded(.down)) )
            .offset(y: CGFloat(hour - CGFloat(startHour)) * spacing )
            Spacer()
        }
    }
    
    private func makeHourLabel( from hour: Int ) -> String {
        if hour == 0 { return "12AM" }
        if hour < 12 { return "\(hour)AM" }
        if hour == 12 { return "12PM" }
        if hour > 12 { return "\(hour - 12)PM" }
        return ""
    }
    
    let day: Date
    let spacing: CGFloat
    
    let startHour: Int
    let endHour: Int
    
    var body: some View {
        ZStack(alignment: .top) {
            ForEach(startHour..<endHour, id: \.self) { hr in
                makeTimeMarker(hour: CGFloat(hr), label: makeHourLabel(from: hr).uppercased(), color: .gray.opacity(0.4))
            }
            
            makeTimeMarker(hour: CGFloat(Date.now.getHoursFromStartOfDay()), label: "", color: .red)
        }
    }
}
