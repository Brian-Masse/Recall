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
        let tags: [RecallCategory] = RealmManager.retrieveObjectsInList()
        
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
        let goals: [RecallGoal] = RealmManager.retrieveObjectsInList()
        
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

//MARK: - StringProtocol
extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

//MARK: - UIScreen
extension UIScreen {
    private static let cornerRadiusKey: String = {
        let components = ["Radius", "Corner", "display", "_"]
        return components.reversed().joined()
    } ()

    public var displayCornerRadius: CGFloat {

        guard let cornerRadius = self.value(forKey: Self.cornerRadiusKey) as? CGFloat else {
            assertionFailure("Failed to detect screen corner radius")
            return 0
        }
        
        return cornerRadius
    }
}
