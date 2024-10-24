//
//  Extensions.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import UIUniversals

//Most extensions used in this app are already provided by UIUniversals (https://github.com/Brian-Masse/UIUniversals)

//MARK: Date
extension Date {
    func round(to rounding: TimeRounding) -> Date {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: self)
        
        let normalizedMinutes = Double(comps.minute ?? 0) / Constants.MinuteTime
        let roundedMinutes = (normalizedMinutes * Double(rounding.rawValue)).rounded(.down) / Double(rounding.rawValue) * Constants.MinuteTime
        let roundedHours =  roundedMinutes == 60 ? (comps.hour ?? 0) + 1 : (comps.hour ?? 0)
        
        return Calendar.current.date(bySettingHour: roundedHours, minute: Int(roundedMinutes), second: 0, of: self) ?? self
    }
    
    func getMonthKey() -> String {
        let style = Date.FormatStyle().month().year()
        return self.formatted(style)
    }
    
    func getDayKey() -> String {
        self.formatted(date: .numeric, time: .omitted)
    }
}

//MARK: Double
extension Double {
    func convertToString() -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        
        return formatter.string(for: self ) ?? "?"
        
    }
    
}
