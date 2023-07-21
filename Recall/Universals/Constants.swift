//
//  Constants.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI

class Colors {
    static var tint: Color { RecallModel.shared.activeColor }
    static var main: Color { accentGreen }
    
    static let colorOptions: [Color] = [.blue]
    
    static let lightGrey = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let darkGrey = Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.9)
    static let accentGreen = makeColor(95, 255, 135)
    
    static let forestGreen = makeColor(80, 120, 87)
    static let deepPurple = makeColor( 91, 45, 234 )
    static let roseGold =  makeColor( 223, 143, 133 )
    static let orange   =  makeColor(239, 140, 86)
    static let oceanBlue = makeColor( 61, 79, 110 )
    static let beige    = makeColor( 122, 104, 89 )
    static let sunnDelight = makeColor( 196, 188, 126 )
    
    private static func makeColor( _ r: CGFloat, _ g: CGFloat, _ b: CGFloat ) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255)
    }
    
}

class Constants {
    
    static let UITitleTextSize: CGFloat     = 45
    static let UIHeaderTextSize: CGFloat    = 30
    static let UISubHeaderTextSize: CGFloat = 20
    static let UIDefaultTextSize: CGFloat   = 15
    static let UISmallTextSize: CGFloat     = 11
    
    static let UIDefaultCornerRadius: CGFloat = 15
    static let UILargeCornerRadius: CGFloat = 30
    static let UIFormSpacing        : CGFloat = 10
    
    static let MinuteTime: Double = 60
    static let HourTime: Double = 3600
    static let DayTime: Double = 86400
    
    static let titleFont: ProvidedFont = .syneHeavy
    static let mainFont: ProvidedFont = .renoMono
    
}
