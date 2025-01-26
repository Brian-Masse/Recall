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
        
        init( title: String, lightAccent: Color, darkAccent: Color, mixValue: Double = 0.020 ) {
            self.title = title
            self.lightAccent = lightAccent
            self.darkAccent = darkAccent
            self.mixValue = mixValue
        }
    }
    
    static let colorOptions: [Color] = [ defaultLightAccent, defaultDarkAccent, blue, purple, grape, pink, red, yellow,  ]
    
    static let classicLightAccent   = Color(66, 122, 69)
    static let classicDarkAccent    = Color(95, 255, 135)
    
    static let lightBeige           = Color( 185, 106, 89 )
    static let darkBeige            = Color( 116, 58, 54 )
    
    static let tangerine            = Color(255, 140, 97)
    
    static let accentColorOptions: [AccentColor] = [
        
            .init(title: "Recall",
                  lightAccent: .init(130, 130, 100),
                  darkAccent: .init(178, 196, 128)),
            
            .init(title: "Classic",
                  lightAccent: classicLightAccent,
                  darkAccent: classicDarkAccent),
        
            .init(title: "purple",
                  lightAccent: Colors.grape.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.grape),
            
            .init(title: "blue",
                  lightAccent: Colors.blue.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.blue),
        
            .init(title: "yellow",
                  lightAccent: Colors.yellow.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.yellow),
            
            .init(title: "red",
                  lightAccent: Colors.red.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.red),
            
            .init(title: "pink",
                  lightAccent: Colors.pink.safeMix(with: .white, by: 0.15),
                  darkAccent: Colors.pink),
            
            .init(title: "beige",
                  lightAccent: Colors.darkBeige,
                  darkAccent: Colors.lightBeige),
            
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
    static let UILargeCornerRadius: CGFloat = 58
    static let subPadding: CGFloat = 7
    
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

struct SFMono: UniversalFont {
    var postScriptName: String = "SF-Mono-Medium"
    
    var fontExtension: String = "otf"
    
    static var shared: UIUniversals.UniversalFont = SFMono()
}

struct SFPro: UniversalFont {
    var postScriptName: String = "SF-Pro"
    
    var fontExtension: String = "ttf"
    
    static var shared: UIUniversals.UniversalFont = SFPro()
}

struct SyneMedium: UniversalFont {
    var postScriptName: String = "Syne-Medium"
    
    var fontExtension: String = "ttf"
    
    static var shared: UIUniversals.UniversalFont = SyneMedium()
}
