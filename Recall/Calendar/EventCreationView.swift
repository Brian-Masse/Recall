//
//  EventCreationView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI
import RealmSwift


struct CalendarEventCreationView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedResults(RecallCategory.self) var categories
    
    @State var title: String = ""
    @State var startTime: Date = .now
    @State var endTime: Date = .now + Constants.HourTime
    
    @State var category: RecallCategory = RecallCategory()
    
    var body: some View {
    
        VStack {
            Form {
                
                Section("Basic Info") {
                    
                    TextField("Event Name", text: $title)
                    
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    
                    BasicPicker(title: "Select Category",
                                noSeletion: "No Selection",
                                sources: Array(categories),
                                selection: $category) { category in Text(category.label) }
                }
            }
            
            Spacer()
            
            RoundedButton(label: "Create Event", icon: "calendar.badge.plus") {
                let event = RecallCalendarEvent(ownerID: RecallModel.ownerID, title: title, startTime: startTime, endTime: endTime, categoryID: category._id)
                RealmManager.addObject(event)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct CategoryCreationView: View {
    
    @State var label: String = ""
    @State var productivity: Float = 0
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Form {
                Section( "Basic Info" ) {
                    
                    TextField("Label", text: $label)
                    
                    Text("Productivity")
                    Slider(value: $productivity, in: -3...3)
                    
                }
            }
            
            RoundedButton(label: "Create Label", icon: "lanyardcard") {
                let category = RecallCategory(ownerID: RecallModel.ownerID, label: label, productivity: productivity)
                RealmManager.addObject(category)
            }
        }
        
        Spacer()
    }
    
}
