//
//  ChartsHelperStructs.swift
//  Recall
//
//  Created by Brian Masse on 8/9/23.
//

import Foundation
import Charts
import SwiftUI
import UIUniversals

//MARK: DataCollection
struct DataCollection<Content: View>: View {
    
    let checkDataLoaded: () -> Bool
    let makeData: () async -> Void
    let content: Content
    
    @State var presentable: Bool = true
    
    init( checkDataLoaded: @escaping () -> Bool, makeData: @escaping () async -> Void, @ViewBuilder content: ()->Content ) {
        self.checkDataLoaded = checkDataLoaded
        self.makeData = makeData
        self.content = content()
    }
    
    var body: some View {
        VStack() {
            if checkDataLoaded() && presentable {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        content
                            .padding(.bottom)
                        
                        HStack {
                            Spacer()
                            UniversalText( RecallModel.ownerID, size: Constants.UISmallTextSize, font: Constants.mainFont  )
                                .onTapGesture { print( RecallModel.ownerID ) }
                                .padding(.bottom, Constants.UIBottomOfPagePadding)
                            Spacer()
                        }
                    }
                }
            } else {
                LoadingPageView(count: 2, height: 250)
                Spacer()
            }
        }
        .onDisappear { presentable = false }
        .onAppear { presentable = true }
        .task { await makeData() }
    }
}

//MARK: HideableDataCollection
struct HideableDataCollection: ViewModifier {

    @State var showing: Bool
    let largeTitle: Bool
    let title: String
    
    private func toggleShowing() { withAnimation { showing.toggle() } }
    
    func body(content: Content) -> some View {
     
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                UniversalText("see all data", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                Image(systemName: showing ? "arrow.up" : "arrow.down")
                Spacer()
            }
            .rectangularBackground(7, style: .secondary)
            .onTapGesture { withAnimation { showing.toggle() } }
            .if(showing) { view in view.padding(.bottom) }
            
            if showing {
                content
            }
        }
    }
}

extension View {
    func hideableDataCollection( _ title: String, largeTitle: Bool = false, defaultIsHidden: Bool = false ) -> some View {
        modifier( HideableDataCollection(showing: !defaultIsHidden, largeTitle: largeTitle, title: title) )
    }
}

