//
//  NavigationCoordinatorView.swift
//  Recall
//
//  Created by Brian Masse on 11/15/24.
//

import Foundation
import SwiftUI

//MARK: - CoordinatorView
struct CoordinatorView: View {
    @ObservedObject private var appCoordinator = ReccallNavigationCoordinator.shared
    
    var body: some View {
        
        NavigationStack(path: $appCoordinator.path) {
            
            appCoordinator.build(.home)
                .navigationDestination(for: RecallNavigationScreen.self) { screen in
                    appCoordinator.build(screen)
                }
                .sheet(item: $appCoordinator.sheet) { sheet in
                    appCoordinator.build(sheet)
                }
                .fullScreenCover(item: $appCoordinator.fullScreenCover) { fullScreenCover in
                    appCoordinator.build(fullScreenCover)
                }
        }
    }
}
