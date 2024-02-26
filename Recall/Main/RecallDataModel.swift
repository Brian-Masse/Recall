//
//  RecallDataModel.swift
//  Recall
//
//  Created by Brian Masse on 8/11/23.
//

import Foundation
import SwiftUI
import UIUniversals


//The dataModel is responsible for computing the data used in the graphs and tables
//throuhgout the app
//It does all of this work asyncrounously to not bottleneck UX performance
class RecallDataModel: ObservableObject {
    
//    MARK: Event Data Aggregators
//    These are the functions that actually compute / aggregate the data
    private func makeData(dataAggregator: (RecallCalendarEvent) -> Double) async -> [DataNode] {
        events.compactMap { event in
            DataNode(date: event.startTime, count: dataAggregator(event), category: event.getTagLabel(), goal: "")
        }.sorted { node1, node2 in node1.category < node2.category }
    }
    
    //    This merges data points that all have the same tag
    private func compressData(from data: [DataNode]) async -> [DataNode] {
        Array( data.reduce(Dictionary<String, DataNode>()) { partialResult, node in
            let key = node.category
            var mutable = partialResult
            if var value = mutable[ key ] {
                mutable[key] = value.increment(by: node.count )
            } else { mutable[key] = .init(date: .now, count: node.count, category: key, goal: "") }
            return mutable
        }.values ).sorted { node1, node2 in node1.count < node2.count }
    }
    
    private func getTotalHours(from data: [DataNode]) async -> Double {
        data.reduce(0) { partialResult, node in partialResult + node.count }
    }
    
    //    period is measured in days
    //    This is purely convenience
    private func getRecentData(from data: [DataNode], in period: Double = 7) async -> [DataNode] {
        data.filter { node in node.date >= .now.resetToStartOfDay() - (period * Constants.DayTime) }
    }
    
    //MARK: Goal Data Aggregators
    
    //  The first is the progress over time, the second is the number of times the goal was met, the third is how many goals were met on that day
    private func makeGoalsProgressOverTimeData() async -> ([DataNode], [DataNode], [DataNode]) {
        var iterator = await RecallModel.getEarliestEventDate()
        
        var progress: [DataNode] = []
        var timesMet: [DataNode] = []
        var goalsMet: [DataNode] = []
        
        while iterator <= (.now.resetToStartOfDay() + Constants.DayTime) {
            
            var goalsMetCount: Int = 0
            
            for goal in goals {
                let progressNum = await 100 * (Double(goal.getProgressTowardsGoal(from: events, on: iterator)) / Double(goal.targetHours))
                let met = await goal.goalWasMet(on: iterator, events: events)
                goalsMetCount += (met ? 1 : 0)
                
                progress.append(.init(date: iterator, count: progressNum, category: "", goal: goal.label))
                timesMet.append(.init(date: iterator, count: met ? 1 : 0, category: "", goal: goal.label))
            }
            
            goalsMet.append(.init(date: iterator, count: Double(goalsMetCount), category: "", goal: ""))
            
            iterator += Constants.DayTime
        }
        return ( progress, timesMet, goalsMet )
    }
    
    private func countNumberOfTimesMet() async -> [DataNode] {
        var metCount: [DataNode] = []
        
        for goal in goals {
            let counts = goalMetCountIndex[ goal.label ] ?? (0, 0)
            metCount.append(.init(date: .now, count: Double(counts.0), category: "completed", goal: goal.label))
            metCount.append(.init(date: .now, count: Double(counts.1), category: "uncompleted", goal: goal.label))
        }
        return metCount
    }
    
    private func getTotalMetData() async -> (Double, Double) {
        let met = metData.filter { node in node.category == "completed" }
        let notMet = metData.filter { node in node.category == "uncompleted" }
        
        let totalMet = met.reduce(0) { partialResult, node in partialResult + node.count }
        let totalNotMet = notMet.reduce(0) { partialResult, node in partialResult + node.count }
        
        return (totalMet, 100 * (totalMet / totalNotMet))
    }
    
    private func makeCompletionPercentageData() async -> [DataNode] {
        goals.compactMap { goal in
            let data = goalMetCountIndex[ goal.label ] ?? (0, 0)
            let percentage = 100 * (Double(data.0) / Double(data.1 + data.0))
            return .init(date: .now, count: percentage, category: "", goal: goal.label)
        }
    }
    
    @MainActor
    private func indexGoalMetCount() async {
        for goal in goals {
            let data = await goal.countGoalMet(from: events)
            goalMetCountIndex[ goal.label ] = data
        }
    }
    
    
    //    MARK: Event Data
//        These are typically used for the charts
    @Published private var hourlyData: [DataNode] = []
//        in general the compressed data is used for data sumarries, that dont need every individaul node
    @Published private var compressedHourlyData: [DataNode] = []
    @Published private var recentHourlyData: [DataNode] = []
    @Published private var recentCompressedHourlyData: [DataNode] = []
    
    @Published private var tagData: [DataNode] = []
    @Published private var compressedTagData: [DataNode] = []
    @Published private var recentTagData: [DataNode] = []
    @Published private var recentCompressedTagData: [DataNode] = []
    
    @Published private var totalHours: Double = 0
    @Published private var recentTotalHours: Double = 0
    
    //   MARK: Goal Data
    @Published var goalsMetOverTimeData   : [DataNode] = []
    
    var countsOverTime                : ([DataNode], [DataNode], [DataNode]) = ([], [], [])
    @Published var progressOverTime       : [DataNode] = []
    @Published var metOverTime            : [DataNode] = []
    
    @Published var metData                : [DataNode] = []
    @Published var totalGoalsMet          : Double = 0
    @Published var totalGoalsMetPercentage : Double = 0
    
    @Published var metPercentageData      : [DataNode] = []
    
    
    //    This is a storage option for the .countGoalMet()
    //    it is used by multiple functions and is computationally significant, so its helpful to temporarily store it in this variable
    //    to quickly access, as opposed to recomputing it every time its needed
    private var goalMetCountIndex: Dictionary<String, (Int, Int)> = Dictionary()
    
    private(set) var events: [RecallCalendarEvent] = []
    private(set) var goals: [RecallGoal] = []
    
    //    MARK: Data Loaded Functions
    //    This states whether the data needed to present the summary page is loaded
    @Published var overviewDataLoaded: Bool = false
    
    @Published var eventsDataLoaded: Bool = false
    
    @Published var goalsDataLoaded: Bool = false
    
    //    this simply takes in the most recent events and goals and stores it in the class
    //    then indexes the goals for use throuhgout most data aggregators
    func storeData( events: [RecallCalendarEvent]? = nil, goals: [RecallGoal]? = nil ) {
        self.events = events ?? self.events
        self.goals = goals ?? self.goals
        
        Task { await self.indexGoalMetCount() }
    }
    
//    MARK: Make Data
//    Not every screen in the DataPage needs access to all this data. So where it can be
//    spared, I wait to compute a certain series of data until it is needed
//    This makes the charts feel more responsive
//    Each of these makeData functions computes all the necccessary data for their given page
    @MainActor
    func makeOverviewData() async {
        
        if RecallModel.shared.dataOverviewValidated { return }
        
        let hourlyData              = await makeData { event in event.getLengthInHours() }
            .sorted { event1, event2 in event1.date > event2.date }
        let compressedHourlyData    = await compressData(from: hourlyData)
        
        let metData                 = await countNumberOfTimesMet()
        self.countsOverTime         = await makeGoalsProgressOverTimeData()
        let goalsMetOverTime        = countsOverTime.2
        
        self.hourlyData             = hourlyData
        self.compressedHourlyData   = compressedHourlyData
        self.metData                = metData
        self.goalsMetOverTimeData   = goalsMetOverTime
            .sorted { event1, event2 in event1.date > event2.date }
        
        RecallModel.shared.setDataOverviewValidation(to: true)
        withAnimation { self.overviewDataLoaded = true }
    }
    
    @MainActor
    func makeEventsData() async {
        
        if RecallModel.shared.dataEventsValidated { return }
        if !overviewDataLoaded { await makeOverviewData() }
        
        let tagData                     = await makeData { _ in 1 }
            .sorted { event1, event2 in event1.date > event2.date }
        let compressedTagData           = await compressData(from: tagData)
        let recentTagData               = await getRecentData(from: tagData)
        let recentCompressedTagData     = await getRecentData(from: compressedTagData)
        
        let recentHourlyData            = await getRecentData(from: hourlyData)
        let recentCompressedHourlyData  = await compressData(from: recentHourlyData)
        
        let totalHours                  = await getTotalHours(from: self.hourlyData)
        let recentTotalHours            = await getTotalHours(from: recentHourlyData)
        
        self.tagData                    = tagData
        self.compressedTagData          = compressedTagData
        self.recentTagData              = recentTagData
        self.recentCompressedTagData    = recentCompressedTagData
        self.recentCompressedHourlyData = recentCompressedHourlyData
        self.recentHourlyData           = recentHourlyData
        self.totalHours                 = totalHours
        self.recentTotalHours           = recentTotalHours
        
        RecallModel.shared.setDataEventsValidated(to: true)
        withAnimation { self.eventsDataLoaded = true }
        
    }
    
    @MainActor
    func makeGoalsData() async {
        
        if RecallModel.shared.dataGoalsValidated { return }
        if !overviewDataLoaded { await makeOverviewData() }
        
        let metPercentageData           = await makeCompletionPercentageData()
        let progressOverTime            = countsOverTime.0
            .filter({ node in node.count > 0 })
            .sorted { event1, event2 in event1.date > event2.date }
        let metOverTime                 = countsOverTime.1
            .filter({ node in node.count > 0 })
            .sorted { event1, event2 in event1.date > event2.date }
        
        let totalData                   = await getTotalMetData()
        let totalGoalsMet               = totalData.0
        let totalGoalsMetPercentage     = totalData.1
        
        self.metPercentageData          = metPercentageData
        self.totalGoalsMet              = totalGoalsMet
        self.totalGoalsMetPercentage    = totalGoalsMetPercentage
        self.progressOverTime           = progressOverTime
        self.metOverTime                = metOverTime
        
        
        RecallModel.shared.setGoalDataValidation(to: true)
        withAnimation { self.goalsDataLoaded = true }
        
    }
    
//    MARK: Convenience Functions
    enum TimePeriod: Int {
        case allTime
        case recent
    }

    func getHourlData(from timePeriod: TimePeriod) -> [DataNode] {
        timePeriod == .recent ? recentHourlyData : hourlyData
    }
    
    func getCompressedHourlData(from timePeriod: TimePeriod) -> [DataNode] {
        timePeriod == .recent ? recentCompressedHourlyData : compressedHourlyData
    }
    
    func getTagData(from timePeriod: TimePeriod) -> [DataNode] {
        timePeriod == .recent ? recentTagData : tagData
    }
    
    func getCompressedTagData(from timePeriod: TimePeriod) -> [DataNode] {
        timePeriod == .recent ? recentCompressedTagData : compressedTagData
    }
    
    func getTotalHours(from timePeriod: TimePeriod) -> Double {
        timePeriod == .recent ? Double(recentTotalHours) : Double(totalHours)
    }
}
