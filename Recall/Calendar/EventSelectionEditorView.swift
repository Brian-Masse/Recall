//
//  EventSelectionEditorView.swift
//  Recall
//
//  Created by Brian Masse on 10/25/23.
//

import Foundation
import SwiftUI
import RealmSwift


struct EventSelectionEditorView: View {

//    MARK: Vars
//    this will likely not be used, its the var stored in the calendar container that says whether or not
//    the user is selecting events
//    it shouldnt be set here though, because thatll kinda fuck with the halfscreen presentation
    @Binding var selecting: Bool
    
    @Binding var selection: [ RecallCalendarEvent ]
    
    @State var date: Date = Date.now

//    MARK: Struct Methods
    private func onDismiss() {
        if !selecting {
            selection = []
        }
    }
    
    private func toggleEvent(_ event: RecallCalendarEvent) {
        if let index = selection.firstIndex(of: event) {
            selection.remove(at: index)
        }
    }
    
//    this runs on the first appear of the selector
    private func setup() {
        self.date = self.selection.first?.startTime ?? .now
    }
    
    @MainActor
    private func submit() {
        
        for event in selection {
            event.updateDateComponent(to: date)
        }
        
        withAnimation { selecting = false }
        
    }
    
//    MARK: ViewBuilders
    
    @MainActor
    @ViewBuilder
    private func makeEventPreivew(_ event: RecallCalendarEvent) -> some View {
        
        HStack {
            Image(systemName: "checkmark")
            UniversalText( event.title, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
        }
            .padding()
            .onTapGesture { toggleEvent(event) }
            .background(
                Rectangle()
                    .foregroundStyle(event.getColor())
                    .cornerRadius(Constants.UIDefaultCornerRadius)
            )
    }
    
    private func formatString() -> String {
        selection.count == 1 ? "event" : "events"
    }
    
    @MainActor
    private func makeEventList() -> some View {
        
        VStack(alignment: .leading) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(selection) { event in
                        makeEventPreivew(event)
                    }
                }
            }
            .secondaryOpaqueRectangularBackground(5)
            HStack {
                UniversalText( "\( selection.count ) \(formatString()) selected", size: Constants.UISmallTextSize, font: Constants.mainFont )
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func makeDateSelector() -> some View {
        StyledDatePicker($date, title: "When did these events happen?", fontSize: Constants.UISubHeaderTextSize)
    }
    
    
//    MARK: Body
    var body: some View {

        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    ScrollView(.vertical) {
                        
                        makeEventList()
                            .padding(.bottom)
                        
                        makeDateSelector()
                            .padding(.bottom, 80)
                        
                        
                        
                    }
                }
                
                LargeRoundedButton("done", icon: "arrow.down") { submit() }
                    .padding(.bottom, 30)
                
//                Spacer()
//                
//                VStack(alignment: .leading) {
//                    pageHeader()
//                    if showingEditorView { Spacer() }
//                }
//                .frame(height: showingEditorView ? geo.size.height * (2/5) : geo.size.height * (1/10))
//                .secondaryOpaqueRectangularBackground()
//                .padding(.bottom, 20)
//                .shadow(color: .black.opacity(0.5), radius: 10, y: 15)
            }
        }
        .ignoresSafeArea()
        .onDisappear() { onDismiss() }
        .onAppear() { setup() }
    }
}
