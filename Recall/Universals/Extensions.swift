//
//  Extensions.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI

extension Color {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {

        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            // You can handle the failure here as you want
            return (0, 0, 0, 0)
        }

        return (r, g, b, o)
    }

    var hex: String {
        String(
            format: "#%02x%02x%02x%02x",
            Int(components.red * 255),
            Int(components.green * 255),
            Int(components.blue * 255),
            Int(components.opacity * 255)
        )
    }
}

extension Date {
    
    func getHoursFromStartOfDay() -> Double {
        let comps = Calendar.current.dateComponents([.minute, .hour], from: self)
        return Double(comps.minute ?? 0) / Constants.MinuteTime + Double(comps.hour ?? 0)
    }
    
    func resetToStartOfDay() -> Date {
        Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self) ?? self
    }
    
    func matches(_ secondDate: Date, to component: Calendar.Component) -> Bool {
        Calendar.current.isDate(self, equalTo: secondDate, toGranularity: component)
    }
    
    func dateBySetting(hour: Double) -> Date {
        let intHour = Int(hour)
        let minutes = (hour - Double(intHour)) * Constants.MinuteTime
        
        return Calendar.current.date(bySettingHour: intHour, minute: Int(minutes), second: 0, of: self) ?? self
    }
    
    func day() -> Int {
        Calendar.current.component(.day, from: self)
    }
    
    func round(to rounding: TimeRounding) -> Date {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: self)
        
        let normalizedMinutes = Double(comps.minute ?? 0) / Constants.MinuteTime
        let roundedMinutes = (normalizedMinutes * Double(rounding.rawValue)).rounded(.down) / Double(rounding.rawValue) * Constants.MinuteTime
        let roundedHours =  roundedMinutes == 60 ? (comps.hour ?? 0) + 1 : (comps.hour ?? 0)
        
        return Calendar.current.date(bySettingHour: roundedHours, minute: Int(roundedMinutes), second: 0, of: self) ?? self
    }
    
    func isFirstOfMonth() -> Bool {
        let components = Calendar.current.dateComponents([.day], from: self)
        return components.day == 1
    }
}

extension Collection {
    func countAll(where query: ( Self.Element ) -> Bool ) -> Int {
        self.filter(query).count
    }
}

extension Float {
    func round(to digits: Int) -> Float {
        (self * pow(10, Float(digits))).rounded(.down) / ( pow(10, Float(digits)) )
    }
}

extension Double {
    func round(to digits: Int) -> Double {
        (self * pow(10, Double(digits))).rounded(.down) / ( pow(10, Double(digits)) )
    }
}

extension String {
    func removeFirst( of char: Character ) -> String {
        if let index = self.firstIndex(of: char) {
            var t = self
            t.remove(at: index)
            return t
        }
        return self
    }
}
