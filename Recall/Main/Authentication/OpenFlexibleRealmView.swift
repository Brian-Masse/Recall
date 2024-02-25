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

struct OpenRealmView: View {
    
    @Binding var page: ContentView.EntryPage
    
    let realmManager = RecallModel.realmManager

    var body: some View {
        
        if RealmManager.offline {
            Text("loading Realm")
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

struct OpenFlexibleSyncRealmView: View {
    
    @State var showingAlert: Bool = false
    @State var title: String = ""
    @State var alertMessage: String = ""

    @Binding var page: ContentView.EntryPage
    
    @AsyncOpen(appId: "application-0-incki", timeout: .min) var asyncOpen
    
    struct loadingCase: View {
        let icon: String
        let title: String
        
        var body: some View {
            VStack {
                Spacer()
                
                HStack {
                    ResizableIcon(icon, size: Constants.UIDefaultTextSize)
                    UniversalText(title, size: Constants.UISmallTextSize, font: Constants.mainFont, wrap: true)
                }
                .opacity(0.7)
            }.padding(.bottom)
        }
    }
    
    private func dismissScreen() {
        RecallModel.realmManager.realmLoaded = false
        RecallModel.realmManager.signedIn = false
        RecallModel.realmManager.hasProfile = false
    }

    var body: some View {
        
        GeometryReader { geo in
            ZStack(alignment: .center) {
                
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
                    
                case .progress(let progress):
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
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.backward")
                        UniversalText( "cancel", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                        Spacer()
                    }
                    .onTapGesture { dismissScreen() }
                    
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
