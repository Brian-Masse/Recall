//
//  TabBar.swift
//  Recall
//
//  Created by Brian Masse on 8/22/24.
//

import Foundation
import SwiftUI
import UIUniversals


//    MARK: Tabbar
struct TabBar: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var viewModel: RecallCalendarViewModel = RecallCalendarViewModel.shared
    
    @Namespace private var tabBarNamespace
    @Binding var pageSelection: MainView.MainPage
    
    @State private var showingRecallButton: Bool = true
    @State private var showingCreateEventScreen: Bool = false
    
    private let buttonPadding: Double = 15
//
    private let buttonRadius: Double = 42.5
    private let surroundingPadding: Double = 5
    
//    MARK: TabBarButton
    @ViewBuilder
    private func makeTabBarButton(page: MainView.MainPage, icon: String) -> some View {
        let isActivePage = page == pageSelection
        
        UniversalButton {
            ZStack {
                if page == pageSelection {
                    RoundedRectangle(cornerRadius: 100)
                        .transition(.scale.combined(with: .blurReplace()))
                        .matchedGeometryEffect(id: "highlight", in: tabBarNamespace)
                        .frame(width: buttonRadius * 2, height: buttonRadius * 2 * 2/3)
                        .universalStyledBackgrond(.accent, onForeground: true)
                }
                
                RecallIcon(icon)
                    .bold()
                    .frame(width: 20, height: 20)
                    .foregroundStyle( isActivePage ? .black : ( colorScheme == .dark ? .white : .black ) )
                    .padding(buttonPadding)
            }
            
        } action: {
            pageSelection = page
            
            if page == .calendar {
                if showingRecallButton { showingCreateEventScreen = true }
                showingRecallButton = true
            }
            else { showingRecallButton = false }
        }
    }

    @ViewBuilder
    private func makeRecallButton() -> some View {
        makeTabBarButton(page: .calendar, icon: showingRecallButton ? "arrow.turn.left.up" : "calendar")
            .frame(width: buttonRadius * 2, height: buttonRadius * 2 * (2/3))
            .background {
                RoundedRectangle(cornerRadius: 55)
                    .foregroundStyle(.thinMaterial)
                    .shadow(radius: 5)
            }
    }
    
//    MARK: Body
    var body: some View {
        HStack {
            makeRecallButton()
            
            HStack(spacing: 0) {
                makeTabBarButton(page: .goals, icon: "flag.checkered")
                makeTabBarButton(page: .categories, icon: "tag")
                makeTabBarButton(page: .data, icon: "chart.bar")
            }
            .padding(surroundingPadding)
            .background {
                RoundedRectangle(cornerRadius: 55)
                    .foregroundStyle(.thinMaterial)
                    .shadow(radius: 5)
            }
        }
        .frame(height: (buttonRadius * 2) + (surroundingPadding * 2) )
        .sheet(isPresented: $showingCreateEventScreen) {
            CalendarEventCreationView.makeEventCreationView(currentDay: viewModel.currentDay)
        }
    }
}
