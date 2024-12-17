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

//MARK: - GoalAnnualProgressView
struct GoalAnnualProgressView: View {
    
    @State private var goalHistory: [String : Double] = [:]
    @State private var tags: [RecallCategory] = []
    
    @State private var maxSaturation: Double = 0
    
    @State private var filteringTag: RecallCategory? = nil
    
    let goal: RecallGoal
    
    private func toggleFilteringTag(tag: RecallCategory) {
        if filteringTag == tag { filteringTag = nil }
        else { filteringTag = tag }
        
        Task { await getGoalHistory() }
    }
    
    private func getTags() async {
        let tags: [RecallCategory] = RealmManager.retrieveObjectsInList()
            .filter { $0.worksTowards(goal: goal) }
        
        withAnimation { self.tags = tags }
    }
    
    private func getGoalHistory() async {
        if let store = goal.dataStore {
            
            var maxSaturation: Double = 0
            
            let historyDic: [String:Double] = Array(store.goalHistory)
                .reduce(into: [String: Double]()) { partialResult, node in
                    let contributingHours = node.getContributingHours(filteringBy: filteringTag?._id)
                    partialResult[node.date.formatted(date: .numeric, time: .omitted)] = contributingHours
                    maxSaturation = max(maxSaturation, contributingHours)
                }
            
            withAnimation {
                self.goalHistory = historyDic
                self.maxSaturation = maxSaturation
            }
        }
    }
    
    @ViewBuilder
    private func makeFilter() -> some View {
        Menu {
            ForEach(tags, id: \.self) { tag in
                Button { toggleFilteringTag(tag: tag) } label: {
                    HStack {
                        if tag == filteringTag { Label(tag.label, systemImage: "checkmark") }
                        else { Text(tag.label) }
                    }
                }
            }
            
        } label: {
            HStack {
                UniversalText("filter", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                RecallIcon("line.3.horizontal.decrease.circle")
            }
            .rectangularBackground(10, style: .secondary)
            .universalTextStyle()
        }
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            makeFilter()
            
            YearCalendar(maxSaturation: maxSaturation) { date in
                goalHistory[ date.formatted(date: .numeric, time: .omitted) ] ?? 0
            }
        }
        .animation(.easeInOut, value: filteringTag)
        .task {
            await getTags()
            await getGoalHistory()
        }
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
                        
                        let hours = node.getContributingHours(filteringBy: nil)
                        
                        Text("\(node.date.formatted(date: .numeric, time: .omitted)) -- \(hours)")

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
