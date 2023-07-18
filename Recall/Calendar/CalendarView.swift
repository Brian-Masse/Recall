//
//  CalendarView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct CalendarPieces: ViewModifier {
    
    let components: [ RecallCalendarComponent ]
    let spacing: CGFloat
    
    @State var showingComponent: Bool = false
    @Binding var dragging: Bool
    
    func body(content: Content) -> some View {
        
        ZStack(alignment: .top) {
            content
            
            ForEach( components, id: \.self ) { component in
                CalendarComponentPreviewView(component: component, spacing: spacing, dragging: $dragging)
                    .onTapGesture { showingComponent = true }
                    .fullScreenCover(isPresented: $showingComponent) {
                        CalendarComponentView(component: component,
                                              startDate: component.startTime,
                                              endDate: component.endTime)
                    }
            }
        }
    }
}



struct CalendarContainer: View {
    
    let height: CGFloat
    let components: [RecallCalendarComponent]
    
    @Binding var dragging: Bool
    
    var body: some View {
        
        let hoursToDisplay:CGFloat = 24
        let spacing = height / hoursToDisplay
        
        ZStack(alignment: .top) {
            ForEach(0..<Int(hoursToDisplay), id: \.self) { hr in
                VStack {
                    HStack(alignment: .top) {
                        UniversalText( "\(hr)", size: Constants.UIDefaultTextSize  )
                        
                        Rectangle()
                            .frame(height: 1)
                            .universalTextStyle()
                    }
                    .offset(y: CGFloat(hr) * spacing )
                    Spacer()
                }
            }
        }
        .modifier( CalendarPieces(components: components, spacing: spacing, dragging: $dragging) )
        .frame(height: height)
    }
}

struct CalendarView: View {
    
    @ObservedResults( RecallCalendarComponent.self ) var components
    
    @State var name: String = "name"
    @State var dragging: Bool = false
    
    var body: some View {
        
        GeometryReader { geo in
            ZStack(alignment: .top) {
                
                ScrollView {
                    CalendarContainer(height: geo.size.height, components: Array( components), dragging: $dragging)
                }
                .scrollDisabled(dragging)
                .frame(height: geo.size.height / 2)
                .background(.red.opacity(0.5))
            }
        }.universalBackground()
    }
}
