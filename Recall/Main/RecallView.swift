//
//  ContentView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import SwiftUI

struct RecallView: View {

//    These are all the main pages of Recall
    enum RecallPage: String {
        case splashScreen
        case login
        case profileCreation
        case tutorial
        case app
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var realmManager = RecallModel.realmManager
    
    @State var recallPage: RecallPage = .splashScreen
    
    
//    MARK: Body
    var body: some View {

        Group {
            if !realmManager.signedIn {
                switch recallPage {
                case .splashScreen: SplashScreen(page: $recallPage).slideTransition()
                case .login: LoginView().slideTransition()
                default: Text("hi").onAppear() { recallPage = .splashScreen }
                }
            }
            else if !realmManager.realmLoaded {
                OpenRealmView(page: $recallPage)
                    .environment(\.realmConfiguration, realmManager.configuration)
                    .slideTransition()
            }
            else if ( recallPage == .app) {
                MainView(appPage: $recallPage)
                    .onAppear() { recallPage = .app }
                    .environment(\.realmConfiguration, realmManager.configuration)
                    .slideTransition()
            }
            else if ( recallPage == .tutorial && !RecallModel.index.finishedTutorial ) {
                TutorialViews(page: $recallPage)
                    .slideTransition()
                    .environment(\.realmConfiguration, realmManager.configuration)
            }
            else if ( recallPage == .profileCreation && !RecallModel.realmManager.profileLoaded )  {
                ProfileCreationView(page: $recallPage)
                    .slideTransition()
                    .environment(\.realmConfiguration, realmManager.configuration)
            }
        }
        .onChange(of: recallPage)    { newValue in
            var newPage = newValue
            if newPage == .profileCreation {
                if RecallModel.realmManager.profileLoaded { newPage = .tutorial }
            }
            if newPage == .tutorial {
                if RecallModel.index.finishedTutorial { newPage = .app }
            }
            
            withAnimation { recallPage = newPage }
        }
    }
}
