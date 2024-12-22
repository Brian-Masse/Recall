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

    let makeData: () async -> Void
    let content: Content
    
    @Binding private var dataLoaded: Bool
    @State var presentable: Bool = false
    
    init( dataLoaded: Binding<Bool>, makeData: @escaping () async -> Void, @ViewBuilder content: ()->Content ) {
        self._dataLoaded = dataLoaded
        self.makeData = makeData
        self.content = content()
    }
    
    var body: some View {
        VStack() {
            if dataLoaded && presentable {
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
                CollectionLoadingView(count: 2, height: 250)
                Spacer()
            }
        }
        .onDisappear { presentable = false }
        .task {
            await makeData()
            await RecallModel.wait(for: 0.3)
            withAnimation { presentable = true }
        }
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
                RecallIcon(showing ? "arrow.up" : "arrow.down")
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

