//
//  EventCreationView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI
import RealmSwift


struct GoalRatingsView: View {
    
    @Binding var goalRatings: Dictionary<String, String>
    
    let goals: [RecallGoal]
    
    private func createBinding(forKey key: String, defaultValue: String = "") -> Binding<String> {
        Binding { goalRatings[ key ] ?? defaultValue }
        set: { newValue, _ in goalRatings[key] = newValue }
    }
    
    var body: some View {
        ForEach( goals ) { goal in
            HStack {
                Text( goal.label )
                Spacer()
                TextField("Rating", text: createBinding(forKey: goal.getEncryptionKey() ))
//                    .keyboardType(.numberPad)
                
            }
        }
    }
}

struct CalendarEventCreationView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedResults(RecallCategory.self) var categories
    @ObservedResults(RecallGoal.self) var goals
    
    @State var showingAlert: Bool = false
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    
    @State var title: String = ""
    
    @State var day: Date = .now
    @State var startTime: Date = .now
    @State var endTime: Date = .now + Constants.HourTime
    
    @State var category: RecallCategory = RecallCategory()
    @State var goalRatings: Dictionary<String, String> = Dictionary()
    
    
//    Makes sure that the start and end times are specifed for the correct day
//    If the end time bleeds into the next day, this handles that
    private func setDay() {
        let requestingNewDay = startTime > endTime ? true : false
        
        let startComps = Calendar.current.dateComponents([.hour, .minute, .second], from: startTime)
        let endComps = Calendar.current.dateComponents([.hour, .minute, .second], from: endTime)
        
        startTime = Calendar.current.date(bySettingHour: startComps.hour!, minute: startComps.minute!, second: startComps.second!, of: day)!
        
        endTime = Calendar.current.date(bySettingHour: endComps.hour!, minute: endComps.minute!, second: endComps.second!, of: day + ( requestingNewDay ? Constants.DayTime : 0  ) )!
    }
    
    var body: some View {
    
        VStack {
            Form {
                
                Section("Basic Info") {
                    
                    TextField("Event Name", text: $title)
                    
                    DatePicker("Day", selection: $day, displayedComponents: .date)
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    
                    BasicPicker(title: "Select Category",
                                noSeletion: "No Selection",
                                sources: Array(categories),
                                selection: $category) { category in Text(category.label) }
                }
                
                Section( "Productivity" ) {
                    GoalRatingsView(goalRatings: $goalRatings, goals: Array( goals ))
                }
            }
            
            Spacer()
            
            RoundedButton(label: "Create Event", icon: "calendar.badge.plus") {
                setDay()
                
                let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                                title: title,
                                                startTime: startTime,
                                                endTime: endTime,
                                                categoryID: category._id,
                                                goalRatings: goalRatings)
                RealmManager.addObject(event)
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onChange(of: category) { newValue in
            goalRatings = RecallCalendarEvent.translateGoalRatingList(newValue.goalRatings)
        }
        
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage))
        }
    }
}

struct CategoryCreationView: View {
    
    @ObservedResults( RecallGoal.self ) var goals
    
    @State var label: String = ""
    @State var goalRatings: Dictionary<String, String> = Dictionary()
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Form {
                Section( "Basic Info" ) {
                    
                    TextField("Label", text: $label)
                }
                
                Section( "Productivity" ) {
                    GoalRatingsView(goalRatings: $goalRatings, goals: Array( goals ))
                }
            }
            
            RoundedButton(label: "Create Label", icon: "lanyardcard") {
                let category = RecallCategory(ownerID: RecallModel.ownerID,
                                              label: label,
                                              goalRatings: goalRatings)
                RealmManager.addObject(category)
            }
        }
        
        Spacer()
    }
    
}
