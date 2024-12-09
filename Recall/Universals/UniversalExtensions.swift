//
//  UniversalExtensions.swift
//  Recall
//
//  Created by Brian Masse on 12/15/24.
//

import Foundation

extension Date {
    public func getStartOfMonth() -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    public func getDaysInMonth() -> Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 0
    }
}
