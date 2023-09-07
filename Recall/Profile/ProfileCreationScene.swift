//
//  ProfileCreationScene.swift
//  Recall
//
//  Created by Brian Masse on 9/7/23.
//

import Foundation
import RealmSwift
import SwiftUI

struct ProfileCreationView: View {
    
//    MARK: ProfileCreationScene
    private enum ProfileCreationScene: Int, CaseIterable, Identifiable {
        
        case splash
        case name
        case phoneNumber
        case birthday
        case reminders
        case complete
        
        var id: Int { self.rawValue }
        
        func advanceScene() -> ProfileCreationScene {
            ProfileCreationScene(rawValue:  self.rawValue + 1 ) ?? .splash
        }
        
        func returnScene() -> ProfileCreationScene {
            ProfileCreationScene(rawValue: max( self.rawValue - 1, 0 )) ?? .splash
        }
        
        func getName() -> String {
            switch self {
            case .reminders:    return "preferences"
            case .complete:     return ""
            case .splash:       return ""
            default:            return "demographics"
            }
        }
    }
    
//    MARK: vars
    @State private var activeScene: ProfileCreationScene = .splash
    
    @State var firstName: String    = ""
    @State var lastName: String     = ""
    @State var phoneNumber: Int     = 0
    @State var dateOfBirth: Date    = .now
    
    @State var showingContinueButton: Bool = false
    
//    MARK: ViewBuilders
    
    @ViewBuilder
    private func makeHeader() -> some View {
        
        ZStack {
            HStack {
                if activeScene.rawValue > 0 {
                    Image(systemName: "arrow.backward")
                    UniversalText( "back", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                    Spacer()
                }
            }
            .onTapGesture { withAnimation {
                activeScene = activeScene.returnScene()
            } }
            
            UniversalText( activeScene.getName(), size: Constants.UIDefaultTextSize, font: Constants.titleFont )
        }
    }
    
    @ViewBuilder
    private func makeNextButton() -> some View {
        
        ConditionalLargeRoundedButton(title: "continue", icon: "arrow.forward") { showingContinueButton } action: {
            
            activeScene = activeScene.advanceScene()
            
            
            
        }

        
    }

    @ViewBuilder
    private func makeSplashScreen() -> some View {
        VStack {
            Spacer()
            UniversalText("Get started by setting up your Recall profile", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                .padding(.trailing, 30)
                .universalForegroundColor()
                .onAppear { showingContinueButton = true }
            Spacer()
        }
        .slideTransition()
    }
    
    
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            makeHeader()
            
            VStack {
                switch activeScene {
                case .splash:       makeSplashScreen()
                default:            Text("hi")
                }
            }
            Spacer()
            
            makeNextButton()
            
            
        }
        .padding(7)
        .universalBackground()
    }
}
