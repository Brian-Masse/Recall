//
//  CalendarComponentView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct CalendarComponentView: View {
    
    @Environment( \.presentationMode ) var presentationMode
    @ObservedRealmObject var component: RecallCalendarComponent
 
    @State var editing: Bool = false
    
    @State var startDate: Date
    @State var endDate: Date
    
    var body: some View {
        
        VStack {
                
            HStack {
                
                ShortRoundedButton("Dismiss", icon: "chevron.down") { presentationMode.wrappedValue.dismiss() }
                Spacer()
                UniversalText( component.title, size: Constants.UISubHeaderTextSize, true )
//                Spacer()
//                ShortRoundedButton("Edit", to: "Done", icon: "pencil", to: "checkmark.seal", completed: { editing }) { editing.toggle() }
                
            }
            
            DatePicker(selection: $startDate, displayedComponents: [.hourAndMinute]) { Text("Start Date") }
            
            DatePicker(selection: $endDate, displayedComponents: [.hourAndMinute]) { Text("End Date") }
            
            RoundedButton(label: "Done", icon: "checkmark.seal") {
                component.update(title: component.title, startDate: startDate, endDate: endDate)
            }
            
        }
        .padding()
        .universalBackground()
    }
}
