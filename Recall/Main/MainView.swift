//
//  CalendarView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

//MARK: MainView
struct MainView: View {
    struct RecallData {
        let events: [RecallCalendarEvent]
        let goals: [RecallGoal]
        let tags:  [RecallCategory]
        let summaries: [RecallDailySummary]
    }
    
    //    MARK: Vars
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedResults( RecallCalendarEvent.self,
                      where: { event in event.startTime > RecallModel.getEarliestEventDate() && event.ownerID == RecallModel.ownerID } ) var events
    @ObservedResults( RecallGoal.self,
                      where: { goal in goal.ownerID == RecallModel.ownerID } ) var goals
    @ObservedResults( RecallCategory.self,
                      where: { tag in tag.ownerID == RecallModel.ownerID } ) var tags
    @ObservedResults( RecallDailySummary.self ) var summaries
    
    //    MARK: Body
    var body: some View {
        
        let data = RecallData(events: Array(events), goals: Array(goals), tags: Array(tags), summaries: Array(summaries))
    
        CoordinatorView(data: data)
            .ignoresSafeArea(.keyboard)
            .task {
                Constants.setupConstants()
                RecallModel.dataModel.storeData( events: data.events, goals: data.goals )
            }
            .onChange(of: events) { RecallModel.shared.updateEvents(Array(events)) }
            .universalBackground()
    }
}



