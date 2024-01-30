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
    
    private func setupUIUniversals() {
        
        Colors.setColors(baseLight:         .init(255, 255, 255),
                         secondaryLight:    .init(235, 235, 235),
                         baseDark:          .init(0, 0, 0),
                         secondaryDark:     .init(25.5, 25.5, 25.5),
                         lightAccent:       .init(66, 122, 69),
                         darkAccent:        .init(95, 255, 135))
        
        Constants.UIDefaultCornerRadius = 20
        
        Constants.setFontSizes(UILargeTextSize: 90,
                               UITitleTextSize: 45,
                               UIHeaderTextSize: 30,
                               UISubHeaderTextSize: 20,
                               UIDefeaultTextSize: 15,
                               UISmallTextSize: 11)
        
        FontProvider.registerFonts()
        
        Constants.titleFont = FontProvider[.syneHeavy]
        Constants.mainFont = FontProvider[.renoMono]
    }
    
    init() {
        setupUIUniversals()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
