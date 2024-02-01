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

//MARK: Data Picker
struct DataPicker: View {
    
    let optionsCount: Int
    let labels: [String]
    
    let fontSize: Double
    
    @Binding var selectedOption: Int
    
    @Namespace private var picker
    
    @ViewBuilder
    private func makeSelector(from label: String, option: Int ) -> some View {
        HStack {
            Spacer()
            UniversalText(label, size: fontSize, font: Constants.titleFont, wrap: false )
            Spacer()
        }
        .if(selectedOption == option) { view in view.rectangularBackground(style: .accent, foregroundColor: .black) }
        .if(selectedOption != option) { view in view.rectangularBackground(style: .secondary) }
        .onTapGesture { withAnimation { selectedOption = option } }
//        .matchedGeometryEffect(id: "b", in: picker)
        
    }
    
    var body: some View {
        HStack {
            ForEach(0..<optionsCount, id: \.self) { i in
                let label = labels[i]
                makeSelector(from: label, option: i)
            }
        }
        .rectangularBackground(5, style: .secondary)
    }
}

//MARK: DataCollection
struct DataCollection<Content: View>: View {
    
    let label: String
    let content: Content
    
    init( _ label: String, @ViewBuilder content: ()->Content ) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            UniversalText( label, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            
            LazyVStack(alignment: .leading) {
                content
            }
            .rectangularBackground(7, style: .primary, stroke: true)
        }
        .padding(.bottom)
    }
}

//MARK: Seperator
struct Seperator: View {
    
    enum Orientation {
        case horizontal
        case vertical
    }
    
    let orientation: Orientation
    
    var body: some View {
        Rectangle()
            .universalTextField()
//            .foregroundColor(.gray.opacity(0.2))
            .if(orientation == .horizontal) { view in view.frame(height: 1)}
            .if(orientation == .vertical) { view in view.frame(width: 1)}
            .padding(.horizontal, 5)
        
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
                UniversalText( title, size: largeTitle ? Constants.UIHeaderTextSize : Constants.UIDefaultTextSize, font: Constants.titleFont )
                Spacer()
                if largeTitle   { LargeRoundedButton("", icon: showing ? "arrow.up" : "arrow.down") { toggleShowing() } }
                else            { LargeRoundedButton("", icon: showing ? "arrow.up" : "arrow.down", small: true) { toggleShowing() } }
            }.padding(.bottom)
            
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

