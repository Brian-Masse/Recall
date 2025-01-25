//
//  OnboardingTemplates.swift
//  Recall
//
//  Created by Brian Masse on 1/25/25.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - TemplateTagMask
enum TemplateTagMask: String {
    case productivity
    case reading
    case exercising
    case mentalHealth
    case creativity
    case learning
    case music
    case social
    case hobby
    case career
}

//MARK: TemplateManager
struct TemplateManager {
    
    private let goalTempaltesFileName: String = "goalTemplates"
    private let tagTemplatesFileName: String = "tagTemplates"
    
    private enum TagColor {
//        case
    }
    
//    MARK: - GetGoalTemplates
    func getGoalTemplates() -> [TemplateGoal] {
        let path = Bundle.main.path(forResource: goalTempaltesFileName, ofType: "csv", inDirectory: "")
        
        do {
            let content = try String(contentsOfFile: path!, encoding: .utf8)
            
            let parsedCSV: [TemplateGoal] = content.components( separatedBy: "\n")
                .compactMap {
                    let components = $0.components(separatedBy: ",")
                    
                    guard let frequncy =    RecallGoal.GoalFrequence(rawValue: components[2]) else { return nil }
                    guard let priority =    RecallGoal.Priority(rawValue: components[3]) else { return nil }
                    guard let tagMask =     TemplateTagMask(rawValue: components[4].trimmingCharacters(in: .newlines)  ) else { return nil }
                    
                    return .init(components[0],
                                 targetHours: Double(components[1]) ?? 5,
                                 frequency: frequncy,
                                 priority: priority,
                                 tagMask: tagMask)
                }
            
            return parsedCSV
        }
        catch {
            print(error.localizedDescription)
            return []
        }
    }
    
//    MARK: - getTagTemplates
    func getTagTemplates() -> [TemplateTag] {
        let path = Bundle.main.path(forResource: tagTemplatesFileName, ofType: "csv", inDirectory: "")
        
        do {
            let contents = try String(contentsOfFile: path!, encoding: .utf8)
            
            let parsedCSV: [TemplateTag] = contents.components(separatedBy: "\n")
                .compactMap { str in
                    let components = str.components(separatedBy: ",")
                    let color = getTagColor(from: components[1].trimmingCharacters(in: .newlines).lowercased())
                    var goals: [String] = []
                    
//                    get all the contributing goals
                    for i in 2..<components.count {
                        let goal = components[i].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        
                        if !goal.isEmpty { goals.append(goal) }
                    }
                    
                    return TemplateTag(components[0],
                                       color: color,
                                       goals: goals)
                }
                .sorted { tag1, tag2 in
                    return tag1.color.hex >= tag2.color.hex
                }
            
            return parsedCSV
            
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
//    MARK: getTagColor
    func getTagColor(from descriptor: String) -> Color {
        if descriptor == "dark green"   { return Colors.classicLightAccent }
        if descriptor == "tangerine"    { return Colors.tangerine }
        if descriptor == "grey"         { return Color.gray }
        
        let colorOption = Colors.accentColorOptions.first { color in
            color.title.lowercased() == descriptor
        } ?? Colors.accentColorOptions.first
        
        return colorOption!.darkAccent
    }
    
}
