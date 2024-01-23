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
        
        Colors.setColors(baseLight: nil,
                         secondaryLight: nil,
                         baseDark: nil,
                         secondaryDark: nil,
                         lightAccent: nil,
                         darkAccent: .init(255, 0, 0))
        
        Constants.setFontSizes(UITitleTextSize: 45,
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
