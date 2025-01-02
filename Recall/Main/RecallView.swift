//
//  ContentView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import SwiftUI

struct RecallView: View {
    

    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var realmManager = RecallModel.realmManager
    
//    MARK: Body
    var body: some View {

        Group {
            switch realmManager.authenticationState {
            case .splashScreen:
                SplashScreen()
                    .slideTransition()
                
            case .authenticating:
                OnboardingAuthenticationScene(sceneComplete: .constant(true))
                    .slideTransition()
                
            case .openingRealm:
                OpenFlexibleSyncRealmView()
                    .environment(\.realmConfiguration, realmManager.configuration)
                    .slideTransition()
                
            case .creatingProfile:
                ProfileCreationView()
                    .slideTransition()
                    .environment(\.realmConfiguration, realmManager.configuration)
                   
            case .tutorial:
                TutorialViews()
                    .slideTransition()
                    .environment(\.realmConfiguration, realmManager.configuration)
                
            case .error:
                Text("An error occoured")
                
            case .complete:
                MainView()
                    .environment(\.realmConfiguration, realmManager.configuration)
                    .slideTransition()
            }
        }
    }
}
