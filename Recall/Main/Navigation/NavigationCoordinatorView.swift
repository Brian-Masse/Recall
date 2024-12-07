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
        }
    }
}
