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
//    @Binding var selecting: Bool
//    
//    @Binding var selection: [ RecallCalendarEvent ]
    
    @ObservedObject private var viewModel: RecallCalendarContainerViewModel = RecallCalendarContainerViewModel.shared
    
    @State private var date: Date = Date.now
    
    @State private var showingDeletetionAlert: Bool = false

//    MARK: Struct Methods
//    this runs on the first appear of the selector
    private func setup() {
        self.date = viewModel.currentDay
    }
    
    @MainActor
    private func submit() {
        for event in viewModel.selection { event.updateDateComponent(to: date) }
        withAnimation { viewModel.selecting = false }
    }
    
    @MainActor
    private func template() {
        for event in viewModel.selection {
            if !event.isTemplate { event.toggleTemplate() }
        }
        
        withAnimation { viewModel.selecting = false }
    }
    
    @MainActor
    private func delete() {
        for event in viewModel.selection {
            event.delete(preserveTemplate: false)
        }
        
        withAnimation { viewModel.selecting = false }
    }
    
//    MARK: ViewBuilders
    
    @MainActor
    @ViewBuilder
    private func makeEventPreivew(_ event: RecallCalendarEvent) -> some View {
        
        HStack {
            RecallIcon("checkmark")
            UniversalText( event.title, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
        }
            .foregroundStyle(.black)
            .padding()
            .onTapGesture { viewModel.selectEvent(event) }
            .background(
                Rectangle()
                    .foregroundStyle(event.getColor())
                    .cornerRadius(Constants.UIDefaultCornerRadius)
            )
    }
    
    private func formatString() -> String {
        viewModel.selection.count == 1 ? "event" : "events"
    }
    
    @MainActor
    private func makeEventList() -> some View {
        
        VStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.selection) { event in
                        makeEventPreivew(event)
                    }
                }
            }
            .rectangularBackground(5, style: .secondary)
            HStack {
                UniversalText( "\( viewModel.selection.count ) \(formatString()) selected", size: Constants.UISmallTextSize, font: Constants.mainFont )
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
            RecallIcon(icon)
            Spacer()
        }
        .rectangularBackground(style: .secondary)
        .onTapGesture { action() }
        
    }
    
    
//    MARK: Body
    var body: some View {

        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
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
        .padding()
        .ignoresSafeArea()
        .onAppear() { setup() }
        .alert("delete events?", isPresented: $showingDeletetionAlert, actions: {
            Button(role: .destructive) { delete() } label: { Text("delete") }
            Button(role: .cancel) { } label: { Text("cancel") }
        }) {
            Text("This will delete all selected events. This cannot be undone.")
        }
    }
}
