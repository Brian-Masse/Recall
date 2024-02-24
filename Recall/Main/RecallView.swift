//
//  ContentView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import SwiftUI

struct ContentView: View {
    
    enum EntryPage: String {
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
//            the logic flow of these screens is top down last to first.
//            This is so if any views additional conditions get 'cauhgt', as long as the scene progresses, the new screen will present
//            This is mainly to avoid getting caught on the profile creation scene
            if !realmManager.signedIn {
                switch entryPage {
                case .splashScreen: SplashScreen(page: $entryPage).slideTransition()
                case .login: LoginView().slideTransition()
                default: Text("hi").onAppear() { entryPage = .splashScreen }
                }
            }
            else if !realmManager.realmLoaded {
                OpenRealmView(page: $entryPage)
                    .environment(\.realmConfiguration, realmManager.configuration)
                    .slideTransition()
            }
            else if ( entryPage == .app) {
                MainView(appPage: $entryPage)
                    .onAppear() { entryPage = .app }
                    .environment(\.realmConfiguration, realmManager.configuration)
                    .slideTransition()
            }
            else if ( entryPage == .tutorial && !RecallModel.index.finishedTutorial ) {
                TutorialViews(page: $entryPage)
                    .slideTransition()
                    .environment(\.realmConfiguration, realmManager.configuration)
            }
            else if ( entryPage == .profileCreation && !RecallModel.realmManager.profileLoaded )  {
                ProfileCreationView(page: $entryPage)
                    .slideTransition()
                    .environment(\.realmConfiguration, realmManager.configuration)
            }
        }
        .onChange(of: entryPage)    { newValue in
            switch newValue {
            case .profileCreation:  if RecallModel.realmManager.profileLoaded { withAnimation { entryPage = .tutorial } }
            case .tutorial:         if RecallModel.index.finishedTutorial { withAnimation { entryPage = .app } }
                    
            default: break
            }
        }
    }
}
