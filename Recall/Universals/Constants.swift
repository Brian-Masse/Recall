//
//  Constants.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import Charts
import UIUniversals

//MARK: Colors
extension Colors {
    static let colorOptions: [Color] = [ lightAccent, darkAccent, blue, purple, grape, pink, red, yellow,  ]
}


//MARK: Constants
extension Constants {
//    forms
    static let formQuestionTitleSize: CGFloat = Constants.UIHeaderTextSize
    static let UIFormSpacing      : CGFloat = 10
    static let UIFormPagePadding: CGFloat = 5
    static let UIFormSliderTextFieldWidth: CGFloat = 60
    
//    charts
    static let UICircularProgressWidth: CGFloat = 12
    static let UIBarMarkCOrnerRadius: CGFloat = 5
    static let UIScrollableBarWidth: MarkDimension = 22
    static let UIScrollableBarWidthDouble: Double = 18
    
//    exta
    static let UILargeCornerRadius: CGFloat = 30
    
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
    
    //    texts
        static let tagSplashPurpose: String = "Tags are a way to organize similar types of events in your life, as well as label how those activites contribute to your goals."
        static let goalsSplashPurpose: String = "Goals allow you to automatically count certain activities towards the personal goals in your life."
        
        static let templatesSplashPurpose: String = "Templates allow you save and quickly recall frequent events. To create a template, select an event and click 'make template'"
        static let favoritesSplashPurpose: String =  "Favorites help you remember the experiences and moments most special to you. To favorite an event, select it and click 'favorite'"
}

struct AndaleMono: UniversalFont {
    var postScriptName: String = "AndaleMono"
    
    var fontExtension: String = "ttf"
    
    static var shared: UIUniversals.UniversalFont = AndaleMono()
}
