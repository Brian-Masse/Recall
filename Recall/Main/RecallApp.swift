//
//  RecallApp.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import SwiftUI
import UIUniversals

@main
struct RecallApp: App {
    
//    This sets all the important constants for the UIUniversals Styled to match recall
//    These are initialized on the spot, (as opposed to be constant variables)
//    because they should only be invoked from UIUniversals after this point
    private func setupUIUniversals() {
        Colors.setColors(baseLight:         .init(255, 255, 255),
                         secondaryLight:    .init(240, 240, 240),
                         baseDark:          .init(0, 0, 0),
                         secondaryDark:     .init(25.5, 25.5, 25.5),
                         lightAccent:       .init(130, 130, 100),
                         darkAccent:        .init(199, 204, 145))
        
        Constants.UIDefaultCornerRadius = 20
        
        Constants.setFontSizes(UILargeTextSize: 90,
                               UITitleTextSize: 45,
                               UIMainHeaderTextSize: 35,
                               UIHeaderTextSize: 30,
                               UISubHeaderTextSize: 20,
                               UIDefeaultTextSize: 15,
                               UISmallTextSize: 11)
        
//        This registers all the fonts provided by UIUniversals
        FontProvider.registerFonts()
        Constants.titleFont = FontProvider[.syneHeavy]
        Constants.mainFont = FontProvider[.renoMono]
        
        UITabBar.appearance().isHidden = true
    }
    
//    before anything is done in the app, make sure UIUniversals is properly initialized
    init() { setupUIUniversals() }
    
    var body: some Scene {
        WindowGroup {
            RecallView()
        }
    }
}
