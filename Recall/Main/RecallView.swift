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
        case app
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var realmManager = RecallModel.realmManager
    
    @State var entryPage: EntryPage = .splashScreen
    
    var body: some View {

        Group {
            if !realmManager.signedIn {
                
                switch entryPage {
                case .splashScreen: SplashScreen(page: $entryPage)
                case .login: LoginView()
                default: EmptyView()
                }
                
            } else if !realmManager.realmLoaded {
                OpenFlexibleSyncRealmView()
                    .environment(\.realmConfiguration, realmManager.configuration)
                
            } else if entryPage != .app && !RecallModel.index.finishedTutorial {
                TutorialViews(page: $entryPage)
                
            }else {
                MainView(appPage: $entryPage)
                    .onAppear() { entryPage = .app }
            }
        }
        .onChange(of: colorScheme) { newValue in RecallModel.shared.setActiveColor(from: newValue) }
        .onAppear()                 { RecallModel.shared.setActiveColor(from: colorScheme) }
        
    }
}
