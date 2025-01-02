//
//  RecallDailySummaryView.swift
//  Recall
//
//  Created by Brian Masse on 10/16/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct RecallDailySummaryView: View {
    
//    MARK: Vars
    let summaries: [RecallDailySummary]
    
    @ObservedObject private var viewModel = RecallCalendarContainerViewModel.shared
    
    @State private var dailySummary: RecallDailySummary? = nil
    
    @State private var dailySummaryNotes: String = ""
    @State private var dailySummaryDate: Date = .now
    
    @State private var edittiingSummary: Bool = false
    
//    MARK: Methods
    @MainActor
    private func createNewDailySummary() {
        if let dailySummary {
            dailySummary.update(notes: dailySummaryNotes)
            edittiingSummary = false
        } else {
            let summary = RecallDailySummary(date: dailySummaryDate, notes: dailySummaryNotes)
            RealmManager.addObject(summary)
        }
    }
    
    @MainActor
    private func fetchDailySummary(for date: Date) async {
        self.dailySummaryDate = date
        if let summary = await RecallDailySummary.getSummary(on: date, from: summaries) { withAnimation {
            self.dailySummary = summary
            self.dailySummaryNotes = summary.notes
        } } else { withAnimation {
            self.dailySummary = nil
            self.dailySummaryNotes = ""
        } }
    }
    
    private func incrementDailySummaryDate(by direction: Double) {
        self.edittiingSummary = false
        self.dailySummaryDate += (direction * Constants.DayTime)
        Task { await self.fetchDailySummary(for: dailySummaryDate) }
    }
    
    private func editDailySummary() {
        dailySummaryNotes = dailySummary!.notes
        self.edittiingSummary = true
    }
    
//    MARK: DatePicker
    @ViewBuilder
    private func makeDailySummaryDatePicker() -> some View {
        
        let format = Date.FormatStyle().weekday().month().day()
        
        let onLeftEdge = viewModel.currentDay.matches(dailySummaryDate, to: .day)
        let onRightEdge = dailySummaryDate.matches(viewModel.currentDay - Double(viewModel.daysPerView - 1) * Constants.DayTime, to: .day)
        
        HStack {
            UniversalButton { RecallIcon("chevron.left") } action: { if !onLeftEdge {
                incrementDailySummaryDate(by: 1)
            }}
                .opacity( onLeftEdge ? 0.5 : 1  )
            
            Spacer()
            
            UniversalText( dailySummaryDate.formatted(format), size: Constants.UIDefaultTextSize, font: Constants.titleFont, wrap: false)
            
            Spacer()
            
            UniversalButton { RecallIcon("chevron.right") } action: { if !onRightEdge {
                incrementDailySummaryDate(by: -1)
            }}
            .opacity( onRightEdge ? 0.5 : 1  )
            
        }
        .rectangularBackground(style: .secondary)
        
//        Probably one of the worst days of my life :) Never felt so gutted, confused, guilty, and betrayed. Especially with the juxtoposition to a year ago, dealing with losing aanika permanently is hitting me pretty hard.
        
        if !edittiingSummary && dailySummary != nil {
            UniversalButton { RecallIcon("pencil").rectangularBackground(style: .secondary)
            } action: { editDailySummary() }
        }
    }
    
//    MARK: Layouts
    @ViewBuilder
    private func makeDailySummaryEditor() -> some View {
        StyledTextField(title: "", binding: $dailySummaryNotes, prompt: "add notes about how the day went", type: .multiLine)
            .transition(.blurReplace)
        
        if !dailySummaryNotes.isEmpty {
            UniversalButton {
                HStack {
                    Spacer()
                    
                    UniversalText( "done", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                    RecallIcon("checkmark")
                    
                    Spacer()
                }.rectangularBackground(style: .accent)
            } action: { createNewDailySummary() }
        }
    }
    
    @ViewBuilder
    private func makeDailySummaryNotes() -> some View {
        if edittiingSummary {
            makeDailySummaryEditor()
            
        } else {
            UniversalText( dailySummaryNotes, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                .transition(.blurReplace)
                .padding()
        }
    }
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading) {
            
            UniversalText("Daily Review", size: Constants.UISubHeaderTextSize, font: Constants.titleFont, scale: true)
            
            HStack {
                makeDailySummaryDatePicker()
                Spacer()
            }
            
            if dailySummary != nil {
                makeDailySummaryNotes()
            } else {
                makeDailySummaryEditor()
            }
        }
        .padding(.vertical)
        .task { await fetchDailySummary(for: viewModel.currentDay) }
        .onChange(of: viewModel.currentDay) { Task { await fetchDailySummary(for: viewModel.currentDay) } }
        
    }
}
