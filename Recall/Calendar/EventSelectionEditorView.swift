//
//  EventSelectionEditorView.swift
//  Recall
//
//  Created by Brian Masse on 10/25/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

struct EventSelectionEditorView: View {

//    MARK: Vars
//    this will likely not be used, its the var stored in the calendar container that says whether or not
//    the user is selecting events
//    it shouldnt be set here though, because thatll kinda fuck with the halfscreen presentation
    @Binding var selecting: Bool
    
    @Binding var selection: [ RecallCalendarEvent ]
    
    @State var date: Date = Date.now
    
    @State var showingDeletetionAlert: Bool = false

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
    
    @MainActor
    private func template() {
        for event in selection {
            if !event.isTemplate {
                event.toggleTemplate()
            }
        }
        
        withAnimation { selecting = false }
    }
    
    @MainActor
    private func delete() {
        for event in selection {
            event.delete(preserveTemplate: false)
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
            .foregroundStyle(.black)
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
            .rectangularBackground(5, style: .secondary)
            HStack {
                UniversalText( "\( selection.count ) \(formatString()) selected", size: Constants.UISmallTextSize, font: Constants.mainFont )
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func makeDateSelector() -> some View {
        StyledDatePicker($date, title: "Change the date of the events", fontSize: Constants.UISubHeaderTextSize)
    }
    
    @ViewBuilder
    private func makeSubButton( _ title: String, icon: String, action: @escaping () -> Void) -> some View {
        
        HStack {
            Spacer()
            UniversalText( title, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            Image(systemName: icon)
            Spacer()
        }
        .rectangularBackground(style: .secondary)
        .onTapGesture { action() }
        
    }
    
    
//    MARK: Body
    var body: some View {

        GeometryReader { geo in
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    
                    makeEventList()
                        .padding(.bottom)
                    
                    makeDateSelector()
                        .padding(.bottom)
                    
                    UniversalText("actions", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                    makeSubButton("template", icon: "viewfinder.rectangular") { template() }
                    makeSubButton("favorite", icon: "arrow.up.right") {  }
                    makeSubButton("delete", icon: "trash") { showingDeletetionAlert = true }
                 
                    LargeRoundedButton("done", icon: "arrow.down", wide: true) { submit() }
                        .padding(.bottom, 30)
                    
                }
            }
        }
        .ignoresSafeArea()
        .onTapGesture {  }
        .onDisappear() { onDismiss() }
        .onAppear() { setup() }
        .alert("delete events?", isPresented: $showingDeletetionAlert, actions: {
            Button(role: .destructive) { delete() } label: { Text("delete") }
            Button(role: .cancel) { } label: { Text("cancel") }
        }) {
            Text("This will delete all selected events. This cannot be undone.")
        }
    }
}
