//
//  ContentView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var realmManager = RecallModel.realmManager
    
    var body: some View {

        if !realmManager.signedIn {
            
            LoginView()
            
//            VStack {
//                ProgressView()
//                Text( "Logging in" )
//            }
//            .task { let _ = await realmManager.authUser(credentials: .anonymous) }
            
        }else if !realmManager.realmLoaded {
            OpenFlexibleSyncRealmView()
        }else {
            MainView()
        }
        
    }
}
