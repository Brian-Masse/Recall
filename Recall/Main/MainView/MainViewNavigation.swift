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
            view.secondaryOpaqueRectangularBackground(MacOSSideBar.sideBarPadding)
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
