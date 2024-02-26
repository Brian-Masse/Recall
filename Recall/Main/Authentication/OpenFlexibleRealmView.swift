//
//  OpenFlexibleRealmView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

//MARK: OpenRealmView
//This presents the user with the progess of the realm as it opens
//That process is very different for offline and Online
//When the realm is opened this must move the signInProcess to .profileCreation
struct OpenRealmView: View {
    
    @Binding var page: RecallView.RecallPage
    
    let realmManager = RecallModel.realmManager

    var body: some View {
        
        if RealmManager.offline {
            VStack {
                Spacer()
                LogoAnimation()
                Spacer()
            }
            .task {
                await realmManager.openNonSyncedRealm()
                page = .profileCreation
            }
            
        } else {
            OpenFlexibleSyncRealmView(page: $page)
                .environment(\.realmConfiguration, realmManager.configuration)
        }
    }
}

//MARK: FlexibleSyncRealmView
struct OpenFlexibleSyncRealmView: View {
    
    @State var showingAlert: Bool = false
    @State var title: String = ""
    @State var alertMessage: String = ""

    @Binding var page: RecallView.RecallPage
    
    @AsyncOpen(appId: "application-0-incki", timeout: .min) var asyncOpen
    
//    MARK: LoadingCase
//    This
    struct loadingCase: View {
        let icon: String
        let title: String
        
        var body: some View {
            HStack {
                ResizableIcon(icon, size: Constants.UIDefaultTextSize)
                UniversalText(title, size: Constants.UISmallTextSize, font: Constants.mainFont, wrap: true)
            }
            .opacity(0.7)
            .padding(.bottom)
        }
    }
    
//    if the user cancels the opening of realm, the app should go back to the begining of
//    the sign in process
    private func dismissScreen() {
        RecallModel.realmManager.realmLoaded = false
        RecallModel.realmManager.signedIn = false
        RecallModel.realmManager.hasProfile = false
    }

//    MARK: Body
    var body: some View {
        
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                
                switch asyncOpen {
                case .connecting:
                    VStack {
                        loadingCase(icon: "externaldrive.connected.to.line.below", title: "Connecting to Realm")
                    }
                case .waitingForUser:
                    loadingCase(icon: "screwdriver", title: "Failed to log user into database")
                        .onAppear {
                            title = "Failed to login"
                            alertMessage = "The user does not have access to the database, try a different user or another method of signing in."
                            showingAlert = true
                        }
                    
                case .open(let realm):
                    VStack {
                        loadingCase(icon: "shippingbox", title: "Loading Assests")
                            .task {
                                await RecallModel.realmManager.authRealm(realm: realm)
                            
                                withAnimation { page = .profileCreation }
                            }
                    }
                    
                case .progress:
                    loadingCase(icon: "server.rack", title: "Downloading Realm from Server")
                    
                case .error(let error):
                    loadingCase(icon: "screwdriver", title: "Error Connecting to Realm")
                        .onAppear {
                            title = "Error Connecting to Realm"
                            alertMessage = "\(error)"
                            showingAlert = true
                        }
                }
                VStack {
                    Spacer()
                    LogoAnimation()
                    Spacer()
                }
            }
            .padding()
            .alert(isPresented: $showingAlert) { Alert(
                title: Text(title),
                message: Text(alertMessage),
                dismissButton: .cancel { dismissScreen() })
            }
            .frame(width: geo.size.width, height: geo.size.height)
            
        }.universalBackground()
    }
}
