//
//  EventCreationView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI
import RealmSwift
import FlowGrid

struct GoalMultiplierSelector: View {
    
    private func makeGoalRatingMultiplier(forKey key: String) -> Binding<Float> {
        Binding { Float(goalRatings[ key ] ?? "0") ?? 0 }
        set: { newValue, _ in goalRatings[key] = "\(Int(newValue))" }
    }
    
    private func makeGoalRatingMultiplierText(forKey key: String) -> Binding<String> {
        Binding { "x\(goalRatings[ key ] ?? "0")" }
        set: { newValue, _ in goalRatings[key] = newValue.removeFirst(of: "x") }
    }
    
    let goal: RecallGoal
    @Binding var goalRatings: Dictionary<String, String>
    
    let showToggle: Bool
    
    var body: some View {
        HStack {
            UniversalText(goal.label, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)

            Spacer()
            
            StyledSlider(minValue: 1, maxValue: 4,
                         binding: makeGoalRatingMultiplier(forKey: goal.key),
                         strBinding: makeGoalRatingMultiplierText(forKey: goal.key),
                         textFieldWidth: 60)
                .frame(width: 150)

            if showToggle {
                Image(systemName: "checkmark")
                    .if( Int( goalRatings[goal.key] ?? "0" ) ?? 0 == 0 ) { view in view.opaqueRectangularBackground() }
                    .if( Int( goalRatings[goal.key] ?? "0" ) ?? 0 != 0 ) { view in view.tintRectangularBackground() }
                
                    .onTapGesture {
                        let rating = Int(goalRatings[goal.key] ?? "0") ?? 0
                        if rating != 0 { goalRatings[goal.key] = "0" }
                        else { goalRatings[goal.key] = "1" }
                    }
            }
        }
        .secondaryOpaqueRectangularBackground()
    }
    
}

//MARK: Creation View
struct CalendarEventCreationView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedResults(RecallCategory.self) var categories
    @ObservedResults(RecallGoal.self) var goals
    
    @State var showingAlert: Bool = false
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    
    let editing: Bool
    let event: RecallCalendarEvent?
    
    @State var title: String
    @State var notes: String
    @State var startTime: Date
    @State var endTime: Date
    @State var day: Date
    
    @State var category: RecallCategory
    @State var goalRatings: Dictionary<String, String>

    @State var showingAllGoals: Bool = false
    
//    MARK: Helper Functions
    
//    Makes sure that the start and end times are specifed for the correct day
//    If the end time bleeds into the next day, this handles that
    private func setDay() {
        let requestingNewDay = startTime > endTime ? true : false
        
        let startComps = Calendar.current.dateComponents([.hour, .minute, .second], from: startTime)
        let endComps = Calendar.current.dateComponents([.hour, .minute, .second], from: endTime)
        
        startTime = Calendar.current.date(bySettingHour: startComps.hour!, minute: startComps.minute!, second: startComps.second!, of: day)!
        endTime = Calendar.current.date(bySettingHour: endComps.hour!, minute: endComps.minute!, second: endComps.second!, of: day + ( requestingNewDay ? Constants.DayTime : 0  ) )!
    }
    
    private func submit() {
        setDay()
        
        if !editing {
            let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                            title: title,
                                            notes: notes,
                                            startTime: startTime,
                                            endTime: endTime,
                                            categoryID: category._id,
                                            goalRatings: goalRatings)
            RealmManager.addObject(event)
        } else {
            event!.update(title: title,
                          notes: notes,
                          startDate: startTime,
                          endDate: endTime,
                          tagID: category._id,
                          goalRatings: goalRatings)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
//    MARK: Bindings
    private var startTimeBinding: Binding<Float> {
        Binding { Float(startTime.getHoursFromStartOfDay().round(to: 2)) }
        set: { newValue, _ in
            startTime = startTime.dateBySetting(hour: Double(newValue)).round(to: .halfHour)
        }
    }
    
    private var startTimeLabel: Binding<String> {
        Binding { startTime.formatted(date: .omitted, time: .shortened) }
        set: { newValue, _ in }
    }
    
    private var endTimeBinding: Binding<Float> {
        Binding { Float(endTime.getHoursFromStartOfDay().round(to: 2)) }
        set: { newValue, _ in
            endTime = endTime.dateBySetting(hour: Double(newValue)).round(to: .halfHour)
        }
    }
    
    private var endTimeLabel: Binding<String> {
        Binding { endTime.formatted(date: .omitted, time: .shortened) }
        set: { newValue, _ in }
    }

//    MARK: Body
    var body: some View {
        VStack(alignment: .leading) {
            
            UniversalText(editing ? "Edit Event" : "Create Event", size: Constants.UITitleTextSize, font: Constants.titleFont)
                .foregroundColor(.black)
            
            ZStack(alignment: .bottom) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        
                        TextFieldWithPrompt(title: "What is the name of this event?", binding: $title)
                        TextFieldWithPrompt(title: "Leave an optional note", binding: $notes)
                            .padding(.bottom)
                        
                        SliderWithPrompt(label: "When did this event start?",
                                         minValue: 0,
                                         maxValue: 23.5,
                                         binding: startTimeBinding,
                                         strBinding: startTimeLabel,
                                         textFieldWidth: 120)
                        
                        SliderWithPrompt(label: "When did this event end?",
                                         minValue: 0,
                                         maxValue: 23.5,
                                         binding: endTimeBinding,
                                         strBinding: endTimeLabel,
                                         textFieldWidth: 120)
                        .padding(.bottom)
                        
                        UniversalText("Select a tag", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                        
                        WrappedHStack(collection: Array( categories )) { tag in
                            HStack {
                                Image(systemName: "tag")
                                UniversalText(tag.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                            }
                            .onTapGesture { category = tag }
                            .if(category.label == tag.label) { view in view.tintRectangularBackground()  }
                            .if(category.label != tag.label) { view in view.secondaryOpaqueRectangularBackground() }
                        }
                        .padding(.bottom)
                        
                        UniversalText("Goals", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                        
                        if category.goalRatings.count > 0 {
                            UniversalText("From Tag", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                            ForEach( Array(goals), id: \.key ) { goal in
                                if category.goalRatings.contains(where: { node in node.key == goal.key }) {
                                    GoalMultiplierSelector(goal: goal, goalRatings: $goalRatings, showToggle: true)
                                }
                            }
                        }
                        
                        HStack {
                            UniversalText("All Goals", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                            Spacer()
                            LargeRoundedButton("", icon: showingAllGoals ? "arrow.up" : "arrow.down") { showingAllGoals.toggle() }
                        }.padding(.top)
                        
                        VStack {
                            if showingAllGoals {
                                ForEach( Array(goals), id: \.key ) { goal in
                                    GoalMultiplierSelector(goal: goal, goalRatings: $goalRatings, showToggle: true)
                                }
                            }
                        }.padding(.bottom, 100)
                    }
                }
                
                LargeRoundedButton("done", icon: "arrow.down") { submit() }
            }
            .opaqueRectangularBackground()
        }
        .padding(Constants.UIFormPagePadding)
        .background(Colors.tint)
        
        .onChange(of: category) { newValue in
            goalRatings = RecallCalendarEvent.translateGoalRatingList(newValue.goalRatings)
        }
        
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage))
        }
    }
}
