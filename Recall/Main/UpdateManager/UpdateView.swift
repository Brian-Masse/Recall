//
//  UpdateView.swift
//  Recall
//
//  Created by Brian Masse on 11/11/23.
//

import Foundation
import SwiftUI



struct UpdateView: View {
    
//    MARK: Vars
    @ObservedObject var updateManager = RecallModel.updateManager
    
    @State var activeUpdateIndex: Int = 0
    @State var activeUpdatePageIndex: Int = 0
    
//    MARK: ViewBuilders
    
    @ViewBuilder
    private func makeTabViewIndicator( pageIndex: Int ) -> some View {
        
        Circle()
            .frame(width: 7, height: 7)
            .onTapGesture { withAnimation { activeUpdatePageIndex = pageIndex }}
            .if(pageIndex != activeUpdatePageIndex) { view in
                view.foregroundStyle( .gray.opacity(0.5) )
            }
            .if(pageIndex == activeUpdatePageIndex) { view in
                view.universalForegroundColor()
            }
    }
    
    @ViewBuilder
    private func makeTabViewIndicators(update: RecallUpdate) -> some View {
        HStack {
            Spacer()
            ForEach(update.pages.indices, id: \.self) { i in
                makeTabViewIndicator(pageIndex: i)
            }
            Spacer()
        }
    }
    
//    MARK: IndividualUpdateView
    @ViewBuilder
    private func makeShowAllUpdatesButton() -> some View {
        Menu {
            ForEach( updateManager.outdatedUpdates.indices, id: \.self ) { i in
                let index = updateManager.outdatedUpdates.count - 1 - i
                ContextMenuButton(updateManager.outdatedUpdates[index].version, icon: "arrow.right") {
                    withAnimation { activeUpdateIndex = index }
                }
            }
        } label: {
            HStack {
                Spacer()
                UniversalText("View all udpates", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                Image(systemName: "arrow.up.doc")
                Spacer()
            }
            .secondaryOpaqueRectangularBackground()
            .universalTextStyle()
        }
    }
    
    @ViewBuilder
    private func makeIndividualUpdateView(update: RecallUpdate, geo: GeometryProxy ) -> some View {
        
        VStack(alignment: .leading) {
            UniversalText( "Whats new in Recall?", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                .padding(.bottom, 5)
                .universalTextStyle()
            
            UniversalText( update.updateDescription, size: Constants.UISmallTextSize, font: Constants.mainFont)
                .padding(.trailing, 20)
                .padding(.bottom)
            
            VStack {
                if update.pages.count > 1 {
                    TabView(selection: $activeUpdatePageIndex) {
                        ForEach( update.pages.indices, id: \.self ) { i in
                            makeUpdatePageView(page: update.pages[i], geo: geo).tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: geo.size.height * (4.5/10))
                    
                    makeTabViewIndicators(update: update)
                        .padding(.bottom, 5)
                    
                } else {
                    makeUpdatePageView(page: update.pages[0], geo: geo, takeFullSapce: false)
                }
            }
            .if( update.pages.count > 1 ) { view in view.opaqueRectangularBackground(5, stroke: true) }
            .padding(.bottom, 7)
            
            makeShowAllUpdatesButton()
            
            LargeRoundedButton("sounds good", icon: "arrow.forward", wide: true) { withAnimation { updateManager.dismissUpdateView() }}
        }
    }
    
//    MARK: UpdatePage
    @ViewBuilder
    private func makeUpdatePageView( page: RecallUpdatePage, geo: GeometryProxy, takeFullSapce: Bool = true ) -> some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( page.pageTitle, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                .padding(5)
            
            if !page.imageName.isEmpty {
                HStack {
                    Spacer()
                    Image(page.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width - 100)
                        .clipped()
                    Spacer()
                }
                .padding(.bottom)
            }
            
            UniversalText( page.pageDescription,
                           size: Constants.UISmallTextSize,
                           font: Constants.mainFont )
            .padding(.trailing, page.imageName.isEmpty ? 10 : 0)
            .padding(.horizontal, 15)
            .padding(.bottom, 5)
            
            if takeFullSapce { Spacer() }
        }
    }
    
    
//    MARK: Body
    var body: some View {
        VStack {
            if updateManager.outdatedClient {
                GeometryReader { geo in
                    ZStack {
                        Rectangle()
                            .reversedUniversalTextStyle()
                            .opacity(0.8)
                        
                        VStack {
                            if updateManager.outdatedUpdates.count > 0 {
                                makeIndividualUpdateView(update: updateManager.outdatedUpdates[activeUpdateIndex], geo: geo)
                            }
                        }
                        .opaqueRectangularBackground()
                        .shadow(color: .black.opacity(0.3),
                                radius: 10, y: 10)
                        .padding()
                    }
                }.transition(.opacity)
            }
        }
    }
}
