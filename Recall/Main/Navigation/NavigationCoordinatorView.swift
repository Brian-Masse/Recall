//
//  NavigationCoordinatorView.swift
//  Recall
//
//  Created by Brian Masse on 11/15/24.
//

import Foundation
import SwiftUI
import RealmSwift
import UIKit



//MARK: - CoordinatorView
struct CoordinatorView: View {
    @ObservedObject private var appCoordinator = RecallNavigationCoordinator.shared
    
    @Namespace private var navigationNapespace
    
    let data: MainView.RecallData
    
    var body: some View {
        
        NavigationStack(path: $appCoordinator.path) {
            
            appCoordinator.build(.home, data: data)
                .navigationDestination(for: RecallNavigationScreen.self) { screen in
                    appCoordinator.build(screen, data: data)
                        .navigationTitle("")
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(true)
                        .interactiveDismissDisabled(true)
                }
                .sheet( item: $appCoordinator.halfScreenSheet, onDismiss: { if let dismiss = appCoordinator.halfScreenSheetDismiss {
                    dismiss()
                } } ) { sheet in
                    appCoordinator.build(sheet, data: data)
                        .presentationDetents([ .fraction(0.25), .large ])
                        .presentationBackgroundInteraction(.enabled)
                }
            
                .sheet(item: $appCoordinator.sheet) { sheet in
                    appCoordinator.build(sheet, data: data)
                        .navigationTitle("")
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(true)
                    
                        .sheet(item: $appCoordinator.sheet2) { sheet in
                            appCoordinator.build(sheet, data: data)
                                .navigationTitle("")
                                .navigationBarBackButtonHidden(true)
                                .navigationBarHidden(true)
                        }
                }
            
                .fullScreenCover(item: $appCoordinator.fullScreenCover) { fullScreenCover in
                    appCoordinator.build(fullScreenCover, data: data)
                        .navigationTitle("")
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(true)
                }
                .onOpenURL { url in
                    if let id = try? ObjectId(string: url.lastPathComponent) {
                        if let event = RecallCalendarEvent.getRecallCalendarEvent(from: id) {
                            appCoordinator.push(.recallEventView(id: "",
                                                                 event: event,
                                                                 events: data.events,
                                                                 Namespace: navigationNapespace))
                        }
                    }
                }
        }
    }
}
