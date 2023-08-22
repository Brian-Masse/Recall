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
        case tutorial 
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
                
                
            }else if !realmManager.realmLoaded {
                OpenFlexibleSyncRealmView()
            }else {
                MainView()
            }
        }
        .onChange(of: colorScheme) { newValue in RecallModel.shared.setActiveColor(from: newValue) }
        .onAppear()                 { RecallModel.shared.setActiveColor(from: colorScheme) }
        
    }
}
