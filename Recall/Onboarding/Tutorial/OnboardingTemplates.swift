//
//  OnboardingTemplates.swift
//  Recall
//
//  Created by Brian Masse on 1/25/25.
//

import Foundation

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
    
//    MARK: GetGoalTemplates
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
}







//MARK: - templateTags
let templateTags: [TemplateTag] = [
    .init("programming", color: .blue, templateMask: [.productivity]),
    .init("went to gym", color: .yellow, templateMask: [.productivity, .exercising]),
]


