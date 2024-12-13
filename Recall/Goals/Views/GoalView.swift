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
    private let width: Double = 20
    
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

//MARK: GoalAnnualProgressView
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

struct GoalView: View {
    
////    MARK: Helpers
//    @ViewBuilder
//    func makeSeperator() -> some View {
//        Rectangle()
//            .universalTextStyle()
//            .frame(width: 1)
//    }
//    
//    @ViewBuilder
//    func makeOverViewDataView(title: String, icon: String, data: String) -> some View {
//        
//        HStack {
//            RecallIcon(icon)
//            UniversalText(title,
//                          size: Constants.UIDefaultTextSize,
//                          font: Constants.mainFont)
//            
//            Spacer()
//            UniversalText(data, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
//        }
//    }
//    
//    @ViewBuilder
//    func makeCircularProgressWidget(title: String, value: Double, total: Double) -> some View {
//        
//        VStack {
//            UniversalText( title, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
//                .padding(.bottom, 5)
//            CircularProgressView(currentValue: value, totalValue: total)
//        }
//        .padding(5)
//        .frame(width: 115)
//        .rectangularBackground(style: .secondary)
//        
//    }
//    
//    MARK: vars
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataModel: RecallGoalDataStore
    
    @ObservedRealmObject var goal: RecallGoal
    @ObservedResults(RecallCategory.self,
                     where: { tag in tag.ownerID == RecallModel.ownerID }) var tags
    
    let events: [RecallCalendarEvent]
    
//    @State var showingEditingScreen: Bool = false
//    @State var showingDeletionAlert: Bool = false
//    
////    MARK: ViewBuilders
//    @ViewBuilder
//    private func makeOverview() -> some View {
//        UniversalText("overview",
//                      size: Constants.UIHeaderTextSize,
//                      font: Constants.titleFont)
//        
//        HStack {
//            UniversalText( goal.goalDescription, size: Constants.UISmallTextSize, font: Constants.mainFont )
//                .frame(width: 100)
//            
//            makeSeperator()
//            
//            VStack {
//                makeOverViewDataView(title: "priority", icon: "exclamationmark.triangle", data: goal.priority)
//                makeOverViewDataView(title: "period", icon: "calendar.day.timeline.leading", data: RecallGoal.GoalFrequence.getType(from: goal.frequency))
//                makeOverViewDataView(title: "goal", icon: "flag.checkered", data: "\(goal.targetHours) \(goal.byTag() ? "tags" : "HR")")
//                makeOverViewDataView(title: "created on", icon: "calendar.badge.clock", data: "\(goal.creationDate.formatted(date: .numeric, time: .omitted))")
//            }
//        }
//        .rectangularBackground(style: .secondary)
//        .padding(.bottom)
//    }
//    
//    @ViewBuilder
//    private func makeContributingTags() -> some View {
//        let contributingTags = tags.filter { tag in tag.worksTowards(goal: goal) }
//        
//        if contributingTags.count != 0 {
//            UniversalText("Contributing Tags", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
//            
//            WrappedHStack(collection: Array(contributingTags)) { tag in
//                HStack {
//                    RecallIcon("arrow.up.right")
//                    UniversalText(tag.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
//                    
//                }
//                .rectangularBackground(style: .primary)
//            }
//            .rectangularBackground(7, style: .secondary)
//        }
//    }
//    
//    @ViewBuilder
//    private func makeQuickActions() -> some View {
//        UniversalText("Quick Actions", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack {
//                LargeRoundedButton("edit", icon: "arrow.up.forward") { showingEditingScreen = true }
//                LargeRoundedButton("delete", icon: "arrow.up.forward") { showingDeletionAlert = true }
//                LargeRoundedButton("change goal target", icon: "arrow.up.forward") { showingEditingScreen = true }
//            }
//        }
//        .rectangularBackground(7, style: .secondary)
//        .padding(.bottom)
//    }
//    
//    @ViewBuilder
//    private func makeGoalReview() -> some View {
//        
//        let progressData = dataModel.progressData
//        let averageData = dataModel.averageData
//        let goalMetData = dataModel.goalMetData
//        
//        UniversalText("Goal Review", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
//            .padding(.bottom)
//        
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack {
//                makeCircularProgressWidget(title: "Current Progress", value: progressData, total: Double(goal.targetHours))
//                
//                makeCircularProgressWidget(title: "Average Activity", value: averageData, total: Double(goal.targetHours))
//                
//                makeCircularProgressWidget(title: "Number of Times met", value: Double(goalMetData.0), total: Double(goalMetData.1 + goalMetData.0))
//            }
//        }
//        
////
//        ActivityPerDay(recentData: false, title: "activites per day", goal: goal, data: dataModel.progressOverTimeData)
//            .frame(height: 160)
//            .padding(5)
//            .rectangularBackground(style: .secondary)
//
//        TotalActivites(title: "total activities", goal: goal, events: events, showYAxis: true)
//            .frame(height: 160)
//            .padding(5)
//            .rectangularBackground(style: .secondary)
//    }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                UniversalText(goal.label, size: Constants.UITitleTextSize, font: Constants.titleFont)
                Spacer()
                LargeRoundedButton("", icon: "arrow.down") { presentationMode.wrappedValue.dismiss() }
            }
            
            GoalAnnualProgressView(goal: goal)
            
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
            
//            ScrollView(.vertical, showsIndicators: false) {
//                VStack(alignment: .leading) {
//                    
//                    makeOverview()
//                    
//                    makeQuickActions()
//
//                    makeGoalReview()
//                    
//                    makeContributingTags()
//                }
//            }
//            Spacer()
        }
        .padding(7)
        .universalBackground()
//        .sheet(isPresented: $showingEditingScreen) { GoalCreationView.makeGoalCreationView(editing: true, goal: goal) }
//        .onAppear { dataModel.makeData(for: goal, with: events) }
//        .alert("Delete Goal?", isPresented: $showingDeletionAlert) {
//            Button(role: .destructive) { goal.delete() } label:    { Label("delete", systemImage: "trash") }
    }
    
    
}
