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
    
    
//    MARK: ViewBuilders
    
    @ViewBuilder
    private func makeIndividualUpdateView(update: RecallUpdate, mainUpdate: Bool, geo: GeometryProxy ) -> some View {
        
        VStack(alignment: .leading) {
            UniversalText( "Whats new in Recall?", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                .padding(.bottom, 5)
            
            UniversalText( update.updateDescription, size: Constants.UISmallTextSize, font: Constants.mainFont)
                .padding(.trailing, 20)
                .padding(.bottom)
            
            TabView {
                ForEach( update.pages, id: \.pageDescription ) { page in
                    makeUpdatePageView(page: page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: geo.size.height * (4.5/10))
            
            LargeRoundedButton("sounds good", icon: "arrow.forward", wide: true) { withAnimation { updateManager.dismissUpdateView() }}
        }
    }
    
    @ViewBuilder
    private func makeUpdatePageView( page: RecallUpdatePage ) -> some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( page.pageTitle, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                .padding(.bottom, 5)
            
            if !page.imageName.isEmpty {
                HStack {
                    Spacer()
                    Image(page.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Spacer()
                }
                .padding(.bottom, 5)
            }
            
            UniversalText( page.pageDescription,
                           size: page.imageName.isEmpty ? Constants.UIDefaultTextSize : Constants.UISmallTextSize,
                           font: Constants.mainFont )
                .padding(.bottom, 5)
            Spacer()
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
                                makeIndividualUpdateView(update: updateManager.outdatedUpdates[ updateManager.outdatedUpdates.count - 1 - activeUpdateIndex],
                                                         mainUpdate: true,
                                                         geo: geo)
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
