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
    
    func day() -> Int {
        Calendar.current.component(.day, from: self)
    }
}

extension Collection {
    
    func countAll(where query: ( Self.Element ) -> Bool ) -> Int {
        self.filter(query).count
    }
    
}
