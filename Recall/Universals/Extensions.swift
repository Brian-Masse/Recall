//
//  Extensions.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: Date
extension Date {
    func round(to rounding: TimeRounding) -> Date {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: self)
        
        let normalizedMinutes = Double(comps.minute ?? 0) / Constants.MinuteTime
        let roundedMinutes = (normalizedMinutes * Double(rounding.rawValue)).rounded(.down) / Double(rounding.rawValue) * Constants.MinuteTime
        let roundedHours =  roundedMinutes == 60 ? (comps.hour ?? 0) + 1 : (comps.hour ?? 0)
        
        return Calendar.current.date(bySettingHour: roundedHours, minute: Int(roundedMinutes), second: 0, of: self) ?? self
    }
}

extension Double {
    
    func convertToString() -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        
        return formatter.string(for: self ) ?? "?"
        
    }
    
}
