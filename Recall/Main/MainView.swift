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
    
//    These are the pages in the main part of the app
    enum MainPage: Int, Identifiable {
        case calendar
        case goals
        case categories
        case data
        
        var id: Int {
            self.rawValue
        }
    }

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
    
    @State var currentPage: MainPage = .calendar
    
    @State private var showingHalfPage: Bool = false
    
    //    MARK: Body
    var body: some View {
        
        let data = RecallData(events: Array(events), goals: Array(goals), tags: Array(tags), summaries: Array(summaries))
    
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                CoordinatorView(data: data)

                if !showingHalfPage {
                    TabBar(pageSelection: $currentPage)
                        .padding(.bottom, 55)
                        .ignoresSafeArea(.keyboard)
                }
                
                UpdateView()
            }
        }
        .ignoresSafeArea(.keyboard)
        .task {
            Constants.setupConstants()
            RecallModel.dataModel.storeData( events: data.events, goals: data.goals )
        }
        .onChange(of: events) { RecallModel.dataModel.storeData( events: Array(events)) }
        .universalBackground()
    }
}
