//
//  ContentView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import SwiftUI

struct ContentView: View {
    
    enum EntryPage {
        case splashScreen
        case login
        case profileCreation
        case tutorial
        case app
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var realmManager = RecallModel.realmManager
    
    @State var entryPage: EntryPage = .splashScreen
    
    var body: some View {
        
        Group {
            if !realmManager.signedIn {
                switch entryPage {
                case .splashScreen: SplashScreen(page: $entryPage).slideTransition()
                case .login: LoginView().slideTransition()
                default: Text("hi").onAppear() { entryPage = .splashScreen }
                }
                
            } else if !realmManager.realmLoaded {
                OpenFlexibleSyncRealmView(page: $entryPage)
                    .environment(\.realmConfiguration, realmManager.configuration)
                    .slideTransition()
                
            } else if (entryPage == .profileCreation || !realmManager.profileLoaded) {
                ProfileCreationView(page: $entryPage)
                    .slideTransition()
            }
            
            else if (entryPage == .tutorial || !RecallModel.index.finishedTutorial) && !RecallModel.index.finishedTutorial {
                TutorialViews(page: $entryPage)
                    .slideTransition()
                
            }
            else {
                MainView(appPage: $entryPage)
                    .onAppear() { entryPage = .app }
                    .environment(\.realmConfiguration, realmManager.configuration)
                    .slideTransition()
            }
        }
        .frame(minWidth: Constants.minAppWidth,
               idealWidth: Constants.idealAppWidth,
               minHeight: Constants.minAppHeight,
               idealHeight: Constants.idealAppHeight)
        .onChange(of: colorScheme) { newValue in RecallModel.shared.setActiveColor(from: newValue) }
        .onAppear()                 { RecallModel.shared.setActiveColor(from: colorScheme) }
        
    }
}
