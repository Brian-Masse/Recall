//
//  Constants.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import Charts

class Colors {
    static var tint: Color { RecallModel.shared.activeColor }
    static var main: Color { accentGreen }
    
    static let colorOptions: [Color] = [ accentGreen, blue, purple, pink, yellow,  ]
    
    static let lightGrey = Color(red: 0.97, green: 0.97, blue: 0.97)
    static let darkGrey = Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.9)
    static let accentGreen = makeColor(95, 255, 135)
    
    static let yellow = makeColor(234, 169, 40)
    static let pink = makeColor(198, 62, 120)
    static let purple = makeColor(106, 38, 153)
    static let blue = makeColor(69, 121, 251)
    
    private static func makeColor( _ r: CGFloat, _ g: CGFloat, _ b: CGFloat ) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255)
    }
    
}

class Constants {
    
//    font sizes
    static let UILargeTextSize: CGFloat     = 90
    static let UITitleTextSize: CGFloat     = 45
    static let UIHeaderTextSize: CGFloat    = 30
    static let UISubHeaderTextSize: CGFloat = 20
    static let UIDefaultTextSize: CGFloat   = 15
    static let UISmallTextSize: CGFloat     = 11
    
//    extra
    static let UIDefaultCornerRadius: CGFloat = 15
    static let UILargeCornerRadius: CGFloat = 30
    static let UIBottomOfPagePadding: CGFloat = 100
    
//    forms
    static let UIFormSpacing      : CGFloat = 10
    static let UIFormPagePadding: CGFloat = 5
    static let UIFormSliderTextFieldWidth: CGFloat = 60
    
//    charts
    static let UICircularProgressWidth: CGFloat = 12
    static let UIBarMarkCOrnerRadius: CGFloat = 5
    static let UIScrollableBarWidth: MarkDimension = 15
    static let UIScrollableBarWidthDouble: Double = 24
    
//    timings
    static let MinuteTime: Double = 60
    static let HourTime: Double = 3600
    static let DayTime: Double = 86400
    static let WeekTime: Double = 604800
    
//    fonts
    static let titleFont: ProvidedFont = .syneHeavy
    static let mainFont: ProvidedFont = .renoMono
    
}
