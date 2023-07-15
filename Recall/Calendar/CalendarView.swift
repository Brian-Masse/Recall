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
    
    func body(content: Content) -> some View {
        
        ZStack(alignment: .top) {
            content
            
            ForEach( components, id: \.self ) { component in
            
                let startTime = component.getStartDate().getHoursFromStartOfDay()
                let endTime = component.getEndDate().getHoursFromStartOfDay()
                let length = endTime - startTime
                
                VStack {
                    
                    UniversalText( component.title, size: Constants.UISubHeaderTextSize, true )
                    UniversalText( component.ownerID, size: Constants.UIDefaultTextSize )
                    
                }
                .padding()
                .opaqueRectangularBackground()
                .offset(y: CGFloat(startTime) * spacing)
                .frame(height: CGFloat(length) * spacing)
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
        .modifier( CalendarPieces(components: components, spacing: spacing) )
        
        .frame(height: height)
    }
}

struct CalendarView: View {
    
    @ObservedResults( RecallCalendarComponent.self ) var components
    
    @State var name: String = "name"
    
    var body: some View {
        
        GeometryReader { geo in
            ZStack(alignment: .top) {
                
                CalendarContainer(height: geo.size.height, components: Array( components ))
                
            
                
//                VStack(alignment: .leading) {
//
//                    Spacer()
//
//                    ForEach( components, id: \._id.stringValue ) { comp in
//                        HStack {
//                            Spacer()
//                            UniversalText(comp.title, size: Constants.UISubHeaderTextSize, true)
//                            UniversalText(comp.ownerID, size: Constants.UIDefaultTextSize)
//                            Spacer()
//                        }
//                        .padding()
//                        .opaqueRectangularBackground()
//                    }
//
//                    TextField("name", text: $name)
//                    RoundedButton(label: "add", icon: "plus") {
//                        let comp = RecallCalendarComponent(ownerID: RecallModel.ownerID, title: name)
//                        RealmManager.addObject(comp)
//                    }
//
//                    Spacer()
//                }
            }
        }.universalBackground()
    }
}
