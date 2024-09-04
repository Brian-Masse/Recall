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
    
    @Namespace private var tabBarNamespace
    @Binding var pageSelection: MainView.MainPage
    
    @State private var timer: Timer? = nil
    @State private var compact: Bool = false
    
    private var primaryPadding: Double { compact ? 15 : 35 }
    
    private var secondaryPadding: Double { compact ? 3 : 10 }
    
//    MARK: TabBarButton
    @ViewBuilder
    private func makeTabBarButton(page: MainView.MainPage, icon: String) -> some View {
        let isActivePage = page == pageSelection
        
        Image(systemName: icon)
            .frame(width: 20, height: 20)
            .foregroundStyle( isActivePage ? .black : ( colorScheme == .dark ? .white : .black ) )
        
            .padding(.vertical, !compact ? primaryPadding : 10)
            .padding(.horizontal, isActivePage ? 35 : secondaryPadding )
            .background {
                if page == pageSelection {
                    Rectangle()
                        .universalStyledBackgrond(.accent, onForeground: true)
                        .cornerRadius(70)
                        .matchedGeometryEffect(id: "highlight", in: tabBarNamespace)
                }
            }
        
            .onTapGesture { withAnimation {
                compact = false
                pageSelection = page
                
                if let timer = self.timer { timer.invalidate() }
            }}
        
    }
    
//    MARK: Body
    var body: some View {
        HStack(spacing: 10) {
            makeTabBarButton(page: .calendar, icon: "calendar") .padding(.leading, pageSelection == .calendar ? 0 : 10 )
            makeTabBarButton(page: .goals, icon: "flag.checkered")
            makeTabBarButton(page: .categories, icon: "tag")
            makeTabBarButton(page: .data, icon: "chart.bar") .padding(.trailing, pageSelection == .data ? 0 : 10 )
        }
        .padding(5)
        .background(.thinMaterial)
        .cornerRadius(55)
        .shadow(radius: 5)
    }
}
