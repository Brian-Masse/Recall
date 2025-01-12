//
//  LifeCalendarView.swift
//  Recall
//
//  Created by Brian Masse on 1/10/25.
//

import Foundation
import SwiftUI
import UIUniversals

struct LifeCalendarView: View {
    @State private var referenceDate: Date = .now
    
    @State private var currentMonth: Int = 0
    
    private let rowCount: Double = 24
    private let spacing: Double = 2
    
    private let expectedYears: Double = 90
    @State private var numberOfCells: Int = 0
    
//    MARK: setup
    private func setup() {
        
        self.referenceDate = RecallModel.index.dateOfBirth
        
        self.numberOfCells = Int(expectedYears * 12)
        self.currentMonth = Int(Date.now.timeIntervalSince( referenceDate ) / (Constants.yearTime) * 12)
    }
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            VStack(alignment: .leading) {
                UniversalText( "Life Progress", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                
                UniversalText( "\(currentMonth) / \(numberOfCells)", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                    .opacity(0.75)
            }
            
            Spacer()
        }
    }
    
//    MARK: makeCalendar
    @ViewBuilder
    private func makeCalendar() -> some View {
        GeometryReader { geo in
            
            let width = (geo.size.width - (1 + rowCount) * spacing) / rowCount
            
            LazyVGrid(columns: [ .init(.adaptive(minimum: width, maximum: width),
                                       spacing: spacing,
                                       alignment: .center) ],
                      alignment: .center,
                      spacing: spacing) {
                
                ForEach( 0..<numberOfCells, id: \.self ) { i in
                    Circle()
                        .frame(width: width, height: width)
                        .opacity( i > currentMonth ? 0.2 : 1 )

                }
            }
        }
    }
    
    
    
//    MARK: - body
    var body: some View {
        
        VStack(alignment: .leading) {
            makeHeader()
            
            makeCalendar()
                .universalStyledBackgrond(.accent, onForeground: true)
        }
        .padding()
        .task { setup() }
        
        
    }
    
}


#Preview {
    LifeCalendarView()
}
