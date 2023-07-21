//
//  GoalView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct GoalView: View {
    
    @ViewBuilder
    func makeSeperator() -> some View {
        Rectangle()
            .universalTextStyle()
            .frame(width: 1)
    }
    
    @ViewBuilder
    func makeOverViewDataView(title: String, icon: String, data: String) -> some View {
        
        HStack {
            Image(systemName: icon)
            UniversalText(title, size: Constants.UIDefaultTextSize, font: mainFont, true)
            
            Spacer()
            UniversalText(data, size: Constants.UIDefaultTextSize, font: mainFont )
        }
        
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedRealmObject var goal: RecallGoal
    
    private let titleFont: ProvidedFont = .syneHeavy
    private let mainFont: ProvidedFont = .renoMono
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack {
                UniversalText(goal.label, size: Constants.UITitleTextSize, font: titleFont, true)
                
                Spacer()
                
                LargeRoundedButton("Edit", icon: "") {  }
                LargeRoundedButton("", icon: "arrow.down") { presentationMode.wrappedValue.dismiss() }
            }
            
            VStack(alignment: .leading) {
                
                UniversalText("overview", size: Constants.UISubHeaderTextSize, font: titleFont, true)
                
                HStack {
                   
                    UniversalText( goal.goalDescription, size: Constants.UISmallTextSize, font: mainFont )
                        .frame(width: 100)
                    
                    makeSeperator()
                    
                    VStack {
                        makeOverViewDataView(title: "tag", icon: "wallet.pass", data: "test")
                        makeOverViewDataView(title: "period", icon: "calendar.day.timeline.leading", data: RecallGoal.GoalFrequence.getType(from: goal.frequency))
                        makeOverViewDataView(title: "goal", icon: "scope", data: "\(goal.targetHours)")
                        
                    }
                }
            }
            .secondaryOpaqueRectangularBackground()
            
            Spacer()
            
        }
            .padding()
            .universalBackground()
    }
    
}
