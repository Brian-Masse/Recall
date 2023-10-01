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
enum MainPage: Identifiable, Equatable {
    case calendar
    case goals( _ priority: RecallGoal.Priority = .all )
    case categories
    case data
    
    var id: Double {
        self.rawValue
    }
}

extension MainPage: RawRepresentable {
    
    public typealias RawValue = Double
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case 0:         self = .calendar
        case 1:         self = .goals()
        case 2:         self = .categories
        case 3:         self = .data
        default:
            return nil
        }
    }
    
    public var rawValue: RawValue {
        switch self {
        case .calendar:     return 0
        case let .goals(priority):
//            This makes sure that the raw value for each subnode of .goals is automatically independent from each other, and from other MainPages
//            The formula is mainly arbitrary
            return pow(Double(2),1 / Double(priority.intRepresentation() + 2) )
        
        case .categories:   return 2
        case .data:        return 3
        }
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
        .if( mainPage == node.page) { view in
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

