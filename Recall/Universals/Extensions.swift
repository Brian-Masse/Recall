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
    
    func getStartOfMonth() -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
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

//MARK: Constants
extension Constants {
    
//    if there are any variables that need to be computed at the start, run their setup code here
    @MainActor
    static func setupConstants() {
        Constants.setTagColorsDic()
        Constants.setGoalColorsDic()
    }
    
//    This is put in constants to avoid being computed every time a colored graph is displayed on screen
    static var tagColorsDic: Dictionary<String, Color> = Dictionary()
    static var goalColorsDic: Dictionary<String, Color> = Dictionary()
    
    @MainActor
    static private func setTagColorsDic() {
        let tags: [RecallCategory] = RealmManager.retrieveObjects()
        
        var dic: Dictionary<String, Color> = Dictionary()
        if tags.count == 0 { return }
        dic["?"] = .white
        for i in 0..<tags.count  {
            let key: String =  tags[i].label
            dic[key] = tags[i].getColor()
        }
        Constants.tagColorsDic = dic
    }
    
    @MainActor
    static private func setGoalColorsDic() {
        let goals: [RecallGoal] = RealmManager.retrieveObjects()
        
        var dic: Dictionary<String, Color> = Dictionary()
        if goals.count == 0 { return }
        dic["?"] = .white
        for i in 0..<goals.count  {
            let key: String =  goals[i].label
            dic[key] = Colors.colorOptions[min( Colors.colorOptions.count - 1, i)]
        }
        Constants.goalColorsDic = dic
    }
    
}
