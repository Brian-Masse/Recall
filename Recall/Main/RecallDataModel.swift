//
//  RecallDataModel.swift
//  Recall
//
//  Created by Brian Masse on 8/11/23.
//

import Foundation
import SwiftUI

class RecallDataModel: ObservableObject {
    
//    MARK: Event Data Aggregators
    
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
//    @Published var countsOverTime         : ([DataNode], [DataNode]) = ([], [])
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
    
//    MARK: Body
    private(set) var events: [RecallCalendarEvent] = []
    private(set) var goals: [RecallGoal] = []
        
    @MainActor
    func updateProperties( events: [RecallCalendarEvent]? = nil, goals: [RecallGoal]? = nil ) async {
        self.events = events ?? self.events
        self.goals = goals ?? self.goals
        
        await onMainRefreshData()
    }

//    MARK: Refresh
    
//    THis is going to be called from a task in some view, meaning it will run on the main thread
//    That prevents any updating issues from occouring when you assign new values to @published vars
//    But should still allow the large, data colleciton code to run without interfering with the view loading
    @MainActor
    func onMainRefreshData() async {
//        events
        hourlyData                  = await makeData { event in event.getLengthInHours() }
        compressedHourlyData        = await compressData(from: hourlyData)
        recentHourlyData            = await getRecentData(from: hourlyData)
        recentCompressedHourlyData  = await getRecentData(from: compressedHourlyData)
//
        tagData                     = await makeData { _ in 1 }
        compressedTagData           = await compressData(from: tagData)
        recentTagData               = await getRecentData(from: tagData)
        recentCompressedTagData     = await getRecentData(from: compressedTagData)

        totalHours                  = await getTotalHours(from: hourlyData)
        recentTotalHours            = await getTotalHours(from: recentHourlyData)
//
////        goals
    
        await indexGoalMetCount()
        
        let countsOverTime              = await makeGoalsProgressOverTimeData()
        
        progressOverTime            = countsOverTime.0
        metOverTime                 = countsOverTime.1
        goalsMetOverTimeData        = countsOverTime.2

        metData                     = await countNumberOfTimesMet()
        
        let totalData               = await getTotalMetData()
        totalGoalsMet               = totalData.0
        totalGoalsMetPercentage     = totalData.1

        metPercentageData           = await makeCompletionPercentageData()
        
    }
    
//    MARK: Convenience Functions
    
//    These functions handle whether to display all data or a select group of recent data
    private func filterIsWeekly(_ viewFilter: Int) -> Bool {
        viewFilter == 0
    }
    
    func getHourlData(from viewFilter: Int) -> [DataNode] {
        filterIsWeekly(viewFilter) ? recentHourlyData : hourlyData
    }
    
    func getCompressedHourlData(from viewFilter: Int) -> [DataNode] {
        filterIsWeekly(viewFilter) ? recentCompressedHourlyData : compressedHourlyData
    }
    
    func getTagData(from viewFilter: Int) -> [DataNode] {
        filterIsWeekly(viewFilter) ? recentTagData : tagData
    }
    
    func getCompressedTagData(from viewFilter: Int) -> [DataNode] {
        filterIsWeekly(viewFilter) ? recentCompressedTagData : compressedTagData
    }
    
    func getTotalHours(from viewFilter: Int) -> Double {
        filterIsWeekly(viewFilter) ? Double(recentTotalHours) : Double(totalHours)
    }
}
