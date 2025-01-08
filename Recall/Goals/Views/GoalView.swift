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
//            IconButton("newspaper") { showingGoalHistoryView = true }
            
            DismissButton()
        }
    }
    
//    MARK: - makeAnnualProgressView
    @State private var filteringTag: RecallCategory? = nil
    
    @ViewBuilder
    private func makeAnnualProgressView() -> some View {
        VStack(alignment: .leading) {
            makeSectionHeader("calendar", title: "\(goal.label) over time")
            
            GoalAnnualProgressView(filteringTag: $filteringTag, goal: goal)
                .padding(.bottom)
            
            ContributingTagListView(filteringTag: $filteringTag, goal: goal)
        }
    }
    
//    MARK: - GoalAnnualProgressView
    struct GoalAnnualProgressView: View {
        
        @State private var goalHistory: [String : Double] = [:]
        @State private var tags: [RecallCategory] = []
        
        @State private var dataLoaded: Bool = false
        
        @State private var maxSaturation: Double = 0
        
        @Binding private var filteringTag: RecallCategory?
        
        private let goal: RecallGoal
        
        private let includeFiltering: Bool
        
        init( filteringTag: Binding<RecallCategory?> = .constant(nil), goal: RecallGoal, includingFiltering: Bool = true) {
            self._filteringTag = filteringTag
            self.goal = goal
            self.includeFiltering = includingFiltering
        }
        
        private func toggleFilteringTag(tag: RecallCategory) {
            if filteringTag == tag { filteringTag = nil }
            else { filteringTag = tag }
        }
        
        private func getTags() async {
            if !tags.isEmpty { return }
            
            let tags: [RecallCategory] = RealmManager.retrieveObjectsInList()
                .filter { $0.worksTowards(goal: goal) }
            
            withAnimation { self.tags = tags }
        }
        
        private func getGoalHistory() async {
            if !goalHistory.isEmpty && !includeFiltering { return }
            self.maxSaturation = 0
            
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
                    self.maxSaturation = min(maxSaturation, Double(goal.targetHours) / 3)
                }
            }
        }
        
//    MARK: GoalAnnualProgressViewBody
        var body: some View {
            VStack(alignment: .trailing) {
                
                if !goalHistory.isEmpty {
                    YearCalendar(maxSaturation: maxSaturation, color: goal.getColor(), forPreview: !includeFiltering) { date in
                        goalHistory[ date.formatted(date: .numeric, time: .omitted) ] ?? 0
                    }
                } else {
                    RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                        .universalStyledBackgrond(.secondary, onForeground: true)
                        .frame(height: 50)
                    
                }
            }
            .animation(.easeInOut, value: filteringTag)
            .task {
                await getTags()
                await getGoalHistory()
            }
            .onChange(of: filteringTag) { Task { await getGoalHistory() } }
        }
    }
    
    
//    MARK: ContributingTagListView
    private struct ContributingTagListView: View {
        
        @State private var tags: [RecallCategory] = []
        @State private var showingAllTags: Bool = false
        
        @Binding var filteringTag: RecallCategory?
        
        let goal: RecallGoal
        
        private func getTags() async {
            if !tags.isEmpty { return }
            let tags: [RecallCategory] = RealmManager.retrieveObjectsInList()
                .filter { tag in tag.worksTowards(goal: goal) }
            
            withAnimation { self.tags = tags }
        }
        
        private func toggleFilteringTag(tag: RecallCategory) {
            if filteringTag == tag { filteringTag = nil }
            else { filteringTag = tag }
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                
                let label = showingAllTags ? "Show Less" : "Show All"
                
                makeSectionHeader("tag", title: "Contributing Tags")
                    .padding(.trailing, 20)
                
                WrappedHStack(collection: tags, spacing: 7) { tag in
                    UniversalText(tag.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                        .rectangularBackground(10, style: .secondary)
                        .opacity( (filteringTag == nil ? 1 : ( filteringTag == tag ? 1 : 0.35 ) ))
                        .onTapGesture { withAnimation { toggleFilteringTag(tag: tag) }}
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
    
//    MARK: - makeOverviewView
    @State private var count: Int = 0
    
    @ViewBuilder
    private func makeOverviewView() -> some View {
        VStack(alignment: .leading) {
            makeSectionHeader("text.alignleft", title: "\(goal.goalDescription)")
            
            HStack {
                makeMetaDataLabel(icon: "circle.badge.exclamationmark",
                                  title: "\(goal.priority) Priority")
                
                makeMetaDataLabel(icon: "arrow.trianglehead.clockwise.rotate.90",
                                  title: goal.getGoalFrequencyDescription())
                
                makeMetaDataLabel(icon: "gauge.with.needle",
                                  title: goal.getTargetHoursDescription())
            }
            .padding(.bottom)
            
            makeSectionHeader("flag.pattern.checkered", title: "Current Progress")
            ProgressBarView(goal: goal)
        }
    }
    
//    MARK: ProgressBarView
    struct ProgressBarView: View {
        
        @State private var currentProgress: Double = 0
        
        let goal: RecallGoal
        
        private func getProgress() async {
            var progress: Double = 0
            if let store = goal.dataStore {
                progress = await store.getCurrentGoalProgress(goalFrequency: goal.frequency)
            }

            withAnimation { currentProgress = progress }
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        
                        RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                            .universalStyledBackgrond(.secondary, onForeground: true)
                        
                        RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                            .frame(width: geo.size.width * min(1, currentProgress / Double(goal.targetHours)))
                            .foregroundStyle(goal.getColor())
                            .overlay(alignment: .trailing) {
                                UniversalText( "\(currentProgress)", size: Constants.UISmallTextSize, font: Constants.mainFont )
                                    .foregroundStyle(.black)
                                    .padding(.trailing)
                            }
                    }
                }.frame(height: 30)
                
                HStack {
                    UniversalText( "0", size: Constants.UISmallTextSize, font: Constants.mainFont )
                    Spacer()
                    UniversalText( "\(goal.targetHours)", size: Constants.UISmallTextSize, font: Constants.mainFont )
                }
                .padding(.horizontal)
                .opacity(0.75)
            }
                .task { await getProgress() }
        }
    }
    
//    MARK: - makeGoalDataView
    private func formatData(_ data: Double) -> String {
        "\(data.round(to: 2))"
    }
    
    @ViewBuilder
    private func makeGoalDataPoint( icon: String, label: String, data: String ) -> some View {
        HStack {
            RecallIcon(icon)
            UniversalText(label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            Spacer()
            
            UniversalText(data, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
        }
        .rectangularBackground(style: .secondary)
    }
    
    @ViewBuilder
    private func makeGoalDataView() -> some View {
        VStack(alignment: .leading) {
            makeSectionHeader("chart.dots.scatter", title: "data")
            
            makeGoalDataPoint(icon: "number",
                              label: "Total Contributions",
                              data: "\(goal.dataStore?.totalContributions ?? 0)" )
            
            makeGoalDataPoint(icon: "gauge.with.needle",
                              label: "Contribution Frequency",
                              data: formatData(goal.dataStore?.getContributionFrequency() ?? 0) )
            
            makeGoalDataPoint(icon: "hourglass.bottomhalf.filled",
                              label: "Total Contributing Hours",
                              data: formatData(goal.dataStore?.totalContributingHours ?? 0) )
            
            makeGoalDataPoint(icon: "camera.metering.center.weighted.average",
                              label: "Average Contribution Time",
                              data: formatData(goal.dataStore?.getAverageHourlyContribution() ?? 0) )
            
            Rectangle()
                .frame(height: 100)
                .foregroundStyle(.clear)
        }
    }
    
    
//    MARK: - GoalViewSection
    @ViewBuilder
    private func makeGoalViewSection<T: View>( first: Bool = false, last: Bool = false, @ViewBuilder contentBuilder: () -> T) -> some View {
        VStack(alignment: .leading) {
            contentBuilder()
                .padding(.top, first ? 10 : 0)
                .padding(.bottom, last ? 10 : 0)
        }
            .rectangularBackground(style: .primary)
            .clipShape( UnevenRoundedRectangle(topLeadingRadius: first ? Constants.UILargeCornerRadius : Constants.UIDefaultCornerRadius,
                                               bottomLeadingRadius: last ? Constants.UILargeCornerRadius : Constants.UIDefaultCornerRadius,
                                               bottomTrailingRadius: last ? Constants.UILargeCornerRadius : Constants.UIDefaultCornerRadius,
                                               topTrailingRadius: first ? Constants.UILargeCornerRadius : Constants.UIDefaultCornerRadius))
    }
    
//    MARK: Content
    @ViewBuilder
    private func makeContent() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 7) {
                
                makeGoalViewSection(first: true) {
                    makeAnnualProgressView()
                }
                
                makeGoalViewSection() {
                    makeOverviewView()
                }
                
                makeGoalViewSection(last: true) {
                    makeGoalDataView()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Constants.UILargeCornerRadius))
    }
    
//    MARK: - Body
    var body: some View {
        
        GeometryReader { geo in
            VStack {
                makeHeader()
                    .padding(.horizontal)
                    .foregroundStyle(.black)
                
                makeContent()
            }
        }
        .padding(5)
        .background( goal.getColor().gradient )
        .ignoresSafeArea(edges: .bottom)
        
        .sheet(isPresented: $showingGoalHistoryView) {
            makeGoalHistory()
                .padding(.top)
        }
    }
    
    
}
