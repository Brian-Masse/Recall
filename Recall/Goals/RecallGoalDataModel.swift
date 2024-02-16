//
//  RecallGoalDataModel.swift
//  Recall
//
//  Created by Brian Masse on 8/17/23.
//

import Foundation
import SwiftUI
import UIUniversals

//This is all the displayed data associated with RecallGoals
//When the preview appears, it will begin computing / aggregating the data into these variables which will automatically update the cooresponding UI.
class RecallGoalDataModel: ObservableObject {
    
//    MARK: Vars
//    This variable controls how many entities to handle when creating previews of the data
    private static var loadLimit = 50
    
    @Published var progressData: Double = 0
    @Published var progressOverTimeData: [DataNode] = []
    @Published var recentProgressOverTimeData: [DataNode] = []
    
    @Published var averageData: Double = 0
    @Published var goalMetData: (Int, Int) = (0, 0)
    
//    These two variables just hold copies of the variabels passed into the make data call
//    This class will eventually be initialized for each goal on the preview page, and then get passed into the full size page if the user taps on it
    private var goal: RecallGoal!
    private var events: [RecallCalendarEvent] = []
    
//    MARK: Convenience Functions
//    indicates whether the data has loaded enough to a point where it can be shown in UI
//    otherwise, show a loading view while the data processes
    var dataLoaded: Bool {
        !recentProgressOverTimeData.isEmpty && !progressOverTimeData.isEmpty
    }
    
    var roundedProgressData: Double { progressData.round(to: 2) }
    
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
        
        let progressData = await goal.getProgressTowardsGoal(from: events)
        let averageData = await goal.getAverage(from: events)
        let goalMetData = await goal.countGoalMet(from: events)
        
        withAnimation {
            self.progressData = progressData
            self.averageData =  averageData
            self.goalMetData =  goalMetData
        }
    }
    
//    This loads previews of data
//    ie. if there is a graph history it will only show the 'loadLimit' amount of data points to the user
//    while the slow load continues in the background
    @MainActor
    private func quickLoadData() async {
        let recentProgressOverTimeData  = await makeProgressOverTimeData(recentData: true)
        let progressOverTimeData        = await makeProgressOverTimeData(recentData: false)
        
        withAnimation {
            self.recentProgressOverTimeData =   recentProgressOverTimeData
            self.progressOverTimeData =         progressOverTimeData
        }
    }
    
    
//    MARK: Data Aggregators
//    This creates a list representing the progress towards the current goal on a certain date. Each event will create a new node with I) the progress towards the goal, II) the goal, and III) the date of that progress.
//    Individual graphs must collect progress nodes on the same date into one point.
//    fastLoad limits the number of entries included in a list to give an output faster
//    recentData only includes events from the past week
    private func makeProgressOverTimeData(fastLoad: Bool = true, recentData: Bool) async -> [DataNode] {

        var fastLoadCount: Int = 0
        var nodes: [DataNode] = []
        
        let weekStart = Date.now.resetToStartOfDay() - ( 7 * Constants.DayTime )
                
        for event in events {
            if fastLoad && fastLoadCount > RecallGoalDataModel.loadLimit { return nodes }
            if recentData && event.startTime < weekStart { return nodes }
        
            let count = await event.getGoalPrgress(goal)
            nodes.append(.init(date: event.startTime,
                               count: count,
                               category: "",
                               goal: goal.label))
            
            fastLoadCount += 1
            
        }
        return nodes

    }
}
