//
//  RecallGoalDataModel.swift
//  Recall
//
//  Created by Brian Masse on 8/17/23.
//

import Foundation
import SwiftUI

class RecallGoalDataModel: ObservableObject {
    
    @Published var progressData: Double = 0
    @Published var progressOverTimeData: [DataNode] = []
    @Published var recentProgressOverTimeData: [DataNode] = []
    
    @Published var averageData: Double = 0
    @Published var goalMetData: (Int, Int) = (0, 0)
    
    
//    These two variables just hold copies of the variabels passed into the make data call
//    This class will eventually be initialized for each goal on the preview page, and then get passed into the full size page if the user taps on it
    private var goal: RecallGoal!
    private var events: [RecallCalendarEvent] = []
    
//    This variable controls how many
    private static var loadLimit = 50
    
//    MARK: Convenience Functions
    var roundedProgressData: Double {
        progressData.round(to: 2)
    }
    
//    This might be arbitrary, but im not exactly sure how Realm provides access with @ObservedResults
//    so this ensures that everything is sorted
    private func sortEvents(from events: [RecallCalendarEvent]) async -> [RecallCalendarEvent] {
        events.sorted { event1, event2 in
            event1.startTime > event2.startTime
        }
    }
    
//    MARK: Make Data
    @MainActor
    func makeData(for goal: RecallGoal, with events: [RecallCalendarEvent]) async {
        
//        store the passed variables in for conveinient access throuhgout the class
        self.goal = goal
        self.events = await sortEvents(from: events)
        
        await quickLoadData()
        
        
        progressData =          await goal.getProgressTowardsGoal(from: events)
        
        averageData = await goal.getAverage(from: events)
        goalMetData = await goal.countGoalMet(from: events)
    }
    
//    This loads previews of data
//    ie. if there is a graph history it will only show the 'loadLimit' amount of data points to the user
//    while the slow load continues in the background
    @MainActor
    private func quickLoadData() async {
        
        recentProgressOverTimeData  = await makeProgressOverTimeData(recentData: true)
        progressOverTimeData        = await makeProgressOverTimeData(fastLoad: false, recentData: false)
        
    }
    
    
//    MARK: Data Aggregators
    
    private func makeProgressOverTimeData(fastLoad: Bool = true, recentData: Bool) async -> [DataNode] {

        var fastLoadCount: Int = 0
        var nodes: [DataNode] = []
        
        let weekStart = Date.now.resetToStartOfDay() - ( 7 * Constants.DayTime )
                
        for event in events {
            if fastLoad && fastLoadCount > RecallGoalDataModel.loadLimit { return nodes }
            if recentData && event.startTime < weekStart { return nodes }
            
//            DispatchQueue.main.sync {
                let count = await event.getGoalPrgress(goal)
                nodes.append(.init(date: event.startTime, count: count, category: "", goal: goal.label))
//            }
            
            fastLoadCount += 1
            
        }
        return nodes

    }
}
