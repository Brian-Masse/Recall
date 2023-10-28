//
//  HalfPageView.swift
//  Recall
//
//  Created by Brian Masse on 10/25/23.
//

import Foundation
import SwiftUI


struct HalfPageView<Content: View>: View {
    
//    MARK: Vars
//    This is the master switch for whether or not the pop up is showing
    @State var showingEditorView: Bool = true
    
    let title: String
    let content: Content
    
    init( _ title: String, contentBuilder: () -> Content ) {
        self.title = title
        self.content = contentBuilder()
    }
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func pageHeader() -> some View {
        HStack {
            UniversalText( title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            
            Spacer()
            
            LargeRoundedButton("", icon: showingEditorView ? "arrow.down" : "arrow.up", wide: false) {
                withAnimation { showingEditorView.toggle() }
            }
        }
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            VStack {
                
                Spacer()
                
                VStack(alignment: .leading) {
                    pageHeader()
                    if showingEditorView { Spacer() }
                }
                .frame(height: showingEditorView ? geo.size.height * (2/5) : geo.size.height * (1/10))
                .secondaryOpaqueRectangularBackground()
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.5), radius: 10, y: 15)
            }
        }
        .ignoresSafeArea()
    }
}
