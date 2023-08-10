//
//  DataPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/31/23.
//

import Foundation
import SwiftUI
import RealmSwift


struct DataPageView: View {
    
    enum DataBookMark: String, Identifiable, CaseIterable {
        case Overview
        case Events
        case Goals
        
        var id: String { self.rawValue }
    }
    
//    MARK: ViewBuilders
    
    @ViewBuilder
    private func makeContentsButton(label: String, proxy: ScrollViewProxy) -> some View {
        HStack {
            Image(systemName: "arrow.up.forward")
            UniversalText(label, size: Constants.UISubHeaderTextSize, font: Constants.titleFont, wrap: false)
        }
        .tintRectangularBackground()
        .onTapGesture { withAnimation { proxy.scrollTo(label, anchor: .top) }}
    }
    
    
    
    @ObservedResults( RecallCalendarEvent.self ) var events
    @ObservedResults( RecallCategory.self ) var tags
    @ObservedResults( RecallGoal.self ) var goals
    
//    MARK: Body
    
    var body: some View {
        
        let arrEvents = Array(events)
//        let arrTags = Array(tags)
        let arrGoals = Array(goals)
        
        VStack(alignment: .leading) {
            
            UniversalText("Data", size: Constants.UITitleTextSize, font: Constants.titleFont)
            
            ScrollViewReader { value in
                ScrollView(.vertical) {
                    
                    LazyVStack(alignment: .leading) {
                        
                        UniversalText("Quick Actions", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach( DataBookMark.allCases ) { content in
                                    makeContentsButton(label: content.rawValue, proxy: value)
                                }
                            }
                        }.opaqueRectangularBackground()
                        
                        GoalsDataSection(events: arrEvents, goals: arrGoals)
                        
                        EventsDataSection(events: arrEvents)
                        
                        Spacer()
                        
                    }
                }
            }
        }
        .padding(7)
        .universalColoredBackground(Colors.tint)
    }
}

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
        .if(selectedOption == option) { view in view.tintRectangularBackground() }
        .if(selectedOption != option) { view in view.secondaryOpaqueRectangularBackground() }
        .onTapGesture { withAnimation { selectedOption = option } }
//        .matchedGeometryEffect(id: "b", in: picker)
        
    }
    
    var body: some View {
        HStack {
            ForEach(0..<optionsCount, id: \.self) { i in
                let label = labels[i]
                makeSelector(from: label, option: i)
            }
        }.secondaryOpaqueRectangularBackground(5)
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
            
            VStack(alignment: .leading) {
                content
            }.opaqueRectangularBackground(7)
        }
        .padding(.bottom, 100)
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
            .if(orientation == .horizontal) { view in view.frame(height: 4)}
            .if(orientation == .vertical) { view in view.frame(width: 4)}
        
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
