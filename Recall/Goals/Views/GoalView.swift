//
//  GoalView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

//MARK: - YearCalendar
struct YearCalendar: View {
    
    let maxSaturation: Double
    let getValue: (Date) -> Double
    
    private let numberOfDays: Int = 365
    private let width: Double = 15
    
//    MARK: YearCalendarDayView
    private struct DayView: View {
        let startDate: Date
        let index: Int
        
        let width: Double
        let maxSaturation: Double
        let getValue: (Date) -> Double
        
        @State private var saturation: Double = 0
        
        private func loadSaturation() async {
            let date = startDate + Constants.DayTime * Double(index)
            let value = getValue(date)
            
            withAnimation { self.saturation = value }
        }
        
        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .frame(width: width, height: width)
                .universalStyledBackgrond(.accent, onForeground: true)
                .opacity(saturation / maxSaturation)
                .task { await loadSaturation() }
        }
    }
    
//    MARK: YearCalendarBody
    var body: some View {
        
        let startDate = Date.now - (Constants.DayTime * Double(numberOfDays))
        let startDateOffset = Calendar.current.component(.weekday, from: startDate) - 1
        let colCount = ceil(Double(numberOfDays + startDateOffset) / 7)
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 3) {
                ForEach(0..<Int(colCount), id: \.self) { col in
                    
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { row in
                            
                            let dateIndex = (col * 7) + row - startDateOffset
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: width, height: width)
                                    .universalStyledBackgrond(.secondary, onForeground: true)
                                
                                if dateIndex > 0 && dateIndex <= numberOfDays {
                                    DayView(startDate: startDate,
                                            index: dateIndex,
                                            width: width,
                                            maxSaturation: maxSaturation,
                                            getValue: getValue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .defaultScrollAnchor(.trailing)
    }
}

//MARK: - GoalAnnualProgressView
struct GoalAnnualProgressView: View {
    
    @State private var goalHistory: [String : Double] = [:]
    
    let goal: RecallGoal
    
    private func getGoalHistory() async {
        if let store = goal.dataStore {
            let historyDic: [String:Double] = Array(store.goalHistory)
                .reduce(into: [String: Double]()) { partialResult, node in
                    partialResult[node.date.formatted(date: .numeric, time: .omitted)] = node.contributingHours
                }
            
            withAnimation { self.goalHistory = historyDic }
        }
    }
    
    var body: some View {
        YearCalendar(maxSaturation: Double(goal.targetHours) / 3.5) { date in
            goalHistory[ date.formatted(date: .numeric, time: .omitted) ] ?? 0
        }
        .task { await getGoalHistory() }
    }
}

//MARK: - GoalView
struct GoalView: View {

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataModel: RecallGoalDataStore
    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
    @ObservedRealmObject var goal: RecallGoal
    
    let events: [RecallCalendarEvent]
    
//    MARK: - GoalHistoryView
    @State private var showingGoalHistoryView: Bool = false
    
    @ViewBuilder
    private func makeGoalHistory() -> some View {
        ScrollView {
            LazyVStack {
                ForEach( 0..<(goal.dataStore?.goalHistory.count ?? 0), id: \.self ) { i in
                    if let node = goal.dataStore?.goalHistory[i] {
                        
                        Text("\(node.date.formatted(date: .numeric, time: .omitted)) -- \( node.contributingHours)")
                            .onAppear {
                                var sum: Double = 0
                                for event in node.contributingEvents {
                                    if let event = RecallCalendarEvent.getRecallCalendarEvent(from: event) {
                                        sum += event.getLengthInHours()
                                    }
                                }
//
                                if sum.round(to: 2) != node.contributingHours.round(to: 2) {
                                    print("sum and contributing hours do not match: \(sum), \(node.contributingHours))")
                                }
                            }
                        
                        ForEach( 0..<node.contributingEvents.count, id: \.self ) { i in
                            if let event = RecallCalendarEvent.getRecallCalendarEvent(from: node.contributingEvents[i]) {
                                Text("\(event.title), (\(event.getLengthInHours())")
                                    .opacity(0.5)
                            }
                        }
                    }
                }
            }
        }.defaultScrollAnchor(.bottom)
    }
    
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            UniversalText(goal.label, size: Constants.UIHeaderTextSize, font: Constants.titleFont)
            Spacer()
            IconButton("newspaper") { showingGoalHistoryView = true }
            
            DismissButton()
        }
    }
    
//    MARK: - makeAnnualProgressView
    @ViewBuilder
    private func makeAnnualProgressView() -> some View {
        VStack(alignment: .leading) {
            makeSectionHeader("calendar", title: "\(goal.label) over time")
            
            GoalAnnualProgressView(goal: goal)
                .padding(.bottom)
            
            ContributingTagListView(goal: goal)
        }
    }
    
//    MARK: ContributingTagListView
    private struct ContributingTagListView: View {
        
        @State private var tags: [RecallCategory] = []
        @State private var showingAllTags: Bool = false
        
        let goal: RecallGoal
        
        private func getTags() async {
            let tags: [RecallCategory] = RealmManager.retrieveObjectsInList()
                .filter { tag in tag.worksTowards(goal: goal) }
            
            withAnimation { self.tags = tags }
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                
                let label = showingAllTags ? "Show Less" : "Show All"
                
                makeSectionHeader("tag", title: "Contributing Tags")
                
                WrappedHStack(collection: tags, spacing: 7) { tag in
                    UniversalText(tag.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                        .rectangularBackground(10, style: .secondary)
                }
                .frame(maxHeight: showingAllTags ? 300 : 40, alignment: .top)
                .clipped()
                
                UniversalButton {
                    UniversalText( label, size: Constants.UISmallTextSize, font: Constants.mainFont )
                        .opacity(0.75)
                        .padding(.leading)
                } action: { showingAllTags.toggle() }
            }
            .onChange(of: showingAllTags) { Task { await getTags() } }
            .task { await getTags() }
        }
    }
    
//    MARK: - GoalViewSection
    @ViewBuilder
    private func makeGoalViewSection<T: View>( @ViewBuilder contentBuilder: () -> T) -> some View {
        VStack(alignment: .leading) {
            contentBuilder()
        }
            .rectangularBackground(style: .primary)
    }
    
//    MARK: Content
    @ViewBuilder
    private func makeContent() -> some View {
        ScrollView {
            LazyVStack(spacing: 7) {
                
                makeGoalViewSection {
                    makeAnnualProgressView()
                }
            }
        }
//        .ignoresSafeArea()
        .scrollClipDisabled()
    }
    
//    MARK: - Body
    var body: some View {
        
        GeometryReader { geo in
            VStack {
                makeHeader()
                    .padding()
                    .foregroundStyle(.black)
                
                makeContent()
                    .frame(height: geo.size.height)
            }
        }
        .background( Colors.getAccent(from: colorScheme).gradient )
        
        .sheet(isPresented: $showingGoalHistoryView) {
            makeGoalHistory()
                .padding(.top)
        }
    }
    
    
}
