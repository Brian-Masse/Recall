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
extension Color {
    ///initialize a color with rgb measured from 0 to 255
    init( _ red: Double, _ green: Double, _ blue: Double ) {
        self.init(red: red / 255, green: green / 255, blue: blue / 255)
    }
    
    func safeMix(with other: Color, by fraction: Double = 0.5) -> Color {
        if #available(iOS 18.0, *) {
            return self.mix(with: other, by: fraction)
        } else {
            return other
        }
    }
}

extension Colors {
    struct AccentColor: Hashable {
        let title: String
        let lightAccent: Color
        let darkAccent: Color
        let mixValue: Double
        
        init( title: String, lightAccent: Color, darkAccent: Color, mixValue: Double = 0.035 ) {
            self.title = title
            self.lightAccent = lightAccent
            self.darkAccent = darkAccent
            self.mixValue = mixValue
        }
    }
    
    static let colorOptions: [Color] = [ defaultLightAccent, defaultDarkAccent, blue, purple, grape, pink, red, yellow,  ]
    
    static let accentColorOptions: [AccentColor] = [
        
            .init(title: "Recall",
                  lightAccent: .init(130, 130, 100),
                  darkAccent: .init(178, 196, 128)),
            
            .init(title: "Classic",
                  lightAccent: .init(66, 122, 69),
                  darkAccent: .init(95, 255, 135),
                  mixValue: 0.025),
     
            .init(title: "blue",
                  lightAccent: Colors.blue.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.blue),
            
            .init(title: "purple",
                  lightAccent: Colors.purple.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.purple,
                  mixValue: 0.025),
            
            .init(title: "grape",
                  lightAccent: Colors.grape.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.grape),
            
            .init(title: "pink",
                  lightAccent: Colors.pink.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.pink),
            
            .init(title: "red",
                  lightAccent: Colors.red.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.red,
                  mixValue: 0.02),
        
            .init(title: "yellow",
                  lightAccent: Colors.yellow.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.yellow)
            
    ]
}


//MARK: Constants
//These are the constants used across the app
//most are already provided by UIUniversals
extension Constants {
//    forms
    static let formQuestionTitleSize: CGFloat = Constants.UISubHeaderTextSize
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
    static let subPadding: CGFloat = 7
    
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

//MARK: Custom Fonts
struct AndaleMono: UniversalFont {
    var postScriptName: String = "AndaleMono"
    
    var fontExtension: String = "ttf"
    
    static var shared: UIUniversals.UniversalFont = AndaleMono()
}
