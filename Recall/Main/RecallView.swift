//
//  CalendarContainerScrollView.swift
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
                    .mainScreenTransition()
                
            case .authenticating:
                OnboardingAuthenticationScene()
                    .mainScreenTransition()
                
            case .openingRealm:
                OpenFlexibleSyncRealmView()
                    .mainScreenTransition()
                    .environment(\.realmConfiguration, realmManager.configuration)
                
            case .creatingProfile:
                ProfileCreationView()
                    .mainScreenTransition()
                    .environment(\.realmConfiguration, realmManager.configuration)
                   
            case .onboarding:
                OnboardingContainerView()
                    .environment(\.realmConfiguration, RecallModel.realmManager.configuration ?? .init())
                    .mainScreenTransition()
                
            case .error:
                Text("An error occoured")
                
            case .complete:
                MainView()  
                    .environment(\.realmConfiguration, realmManager.configuration)
                    .mainScreenTransition()
            }
        }
    }
}
