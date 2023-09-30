//
//  MainViewNavigation.swift
//  Recall
//
//  Created by Brian Masse on 9/27/23.
//

import Foundation
import SwiftUI


//MARK: MainPage
//These are the main pages that are displayed on iOS
enum MainPage: Int, Identifiable, CaseIterable {
    case calendar
    
    case goals
    case high
    case medium
    case low
    
    case categories
    case tags
    case templates
    
    case data
    case overview
    case events
    
    var id: Int {
        self.rawValue
    }
}

//MARK: TabBarNode
//These structures can be used in both the macOS sidebar and iOS tabBar 
struct TabBarNode: Identifiable {
    
    let title: String
    let icon: String
    
    let page: MainPage
    let indent: Bool
    
    init( _ title: String, icon: String, page: MainPage, indent: Bool = false ) {
        self.title = title
        self.icon = icon
        self.page = page
        self.indent = indent
    }
    
    var id: String { title + icon }
}

//MARK: iOS TabBar
#if os(iOS)
struct iOSTabBar: View {
    
//    @Environment(\.colorScheme) var colorScheme
    
    struct TabBarIcon: View {
        
        @Binding var selection: MainPage
        
        let namespace: Namespace.ID
        
        let page: MainPage
        let title: String
        let icon: String
    
        @ViewBuilder private func makeIcon() -> some View {
            Image(systemName: icon)
        }
        
        var body: some View {
            Group {
                if selection == page {
                    makeIcon()
                        .foregroundColor(.black)
                        .padding(.horizontal, 37)
                        .background {
                            Rectangle()
                                .universalForegroundColor()
                                .cornerRadius(70)
                                .frame(width: 90, height: 90)
                                .matchedGeometryEffect(id: "highlight", in: namespace)
                        }
                        .shadow(color: Colors.tint.opacity(0.3), radius: 10)
                    
                } else {
                    makeIcon()
                        .padding(.horizontal, 7)
                }
            }
            .onTapGesture { withAnimation { selection = page }}
        }
    }
    
    @Namespace private var tabBarNamespace
    @Binding var pageSelection: MainPage
    
    var body: some View {
        HStack(spacing: 10) {
            TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .calendar, title: "Recall", icon: "calendar")
                .padding(.leading, pageSelection == .calendar ? 0 : 10 )
            TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .goals, title: "Goals", icon: "flag.checkered")
            TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .categories, title: "Tags", icon: "tag")
            TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .data, title: "Data", icon: "chart.bar")
                .padding(.trailing, pageSelection == .data ? 0 : 10 )
        }
        .padding(7)
        .frame(height: 104)

//            .padding(.bottom, 18)
        .ignoresSafeArea()
        .universalTextStyle()
        .background(.thinMaterial)
        .foregroundStyle(.ultraThickMaterial)
        .cornerRadius(55)
        .shadow(radius: 5)
        .padding(.bottom, 43)
    }
}
#endif


//MARK: MacOS Sidebar
struct MacOSSideBar: View {
    
    @Binding var mainPage: MainPage
    
    static let sideBarPadding: CGFloat = 5
    
    @ViewBuilder
    private func makeSideBarNode( _ node: TabBarNode ) -> some View {
        
        HStack {
            Image( systemName: node.icon )
                .universalForegroundColor()
            
            UniversalText( node.title, size: Constants.UISmallTextSize, font: Constants.mainFont )

            Spacer()
        }
        .padding(.leading, node.indent ? 19 : 0 )
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .if( mainPage.rawValue == node.page.rawValue) { view in
            view
                .padding(MacOSSideBar.sideBarPadding)
                .background(
                    Rectangle()
                        .foregroundColor(.gray)
                        .opacity(0.1)
                        .cornerRadius(Constants.UIDefaultCornerRadius)
                )
        }
        .if( mainPage.rawValue != node.page.rawValue ) { view in
            view
                .padding(MacOSSideBar.sideBarPadding)
        }
        .overlay {
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture { mainPage = node.page }
        }
    }
    
    
    var body: some View {
        
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach( MainView.MacOSTabBarNodes ) { node in
                    makeSideBarNode(node)
                }
                
                Spacer()
            }.padding(5)
        }
    }
}

