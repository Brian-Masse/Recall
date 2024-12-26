//
//  AboutView.swift
//  Recall
//
//  Created by Brian Masse on 12/23/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct OnBoardingView: View {
    
//    private func decomposeString(_ string: String, highlightString: String) -> [String] {
//        
////        if let substring = string.firstInd(of: highlightString) {
//            
//        }
//        
//    }
    
    var body: some View {
        GeometryReader { geo in
            
//            UniversalText("What is Recall",
//                          size: Constants.UITitleTextSize,
//                          font: Constants.titleFont,
//                          textAlignment: .center)
            
//            AboutScreenOverviewScene(in: geo)
        }
    }
}



//MARK: - AboutScreenOverviewScene
struct AboutScreenOverviewScene: View {
    
    
//    MARK: OverviewTexts
    private let texts: [String] = [
        "Recall helps you remember your life",
        "From quick passing events and brief interactions",
        "to your longest, and most meaningful memories"
    ]
    
    private func x(from perc: Double) -> Double {
        geo.size.width * perc
    }
    
    private func y(from perc: Double) -> Double {
        geo.size.height * perc
    }
    
//    MARK: events
    private var events: [AboutScreenEventModel] { [
        .init(event: .init(title: "texted Ben",
                           color: .purple),
              indexOfText: 1,
              relativeDelay: 0,
              position: .init(x: x(from: 0.55), y: y(from: 0.30)),
              size: .init(width: 140, height: 25)),
        
        .init(event: .init(title: "Went for a Jog",
                           color: .orange),
              indexOfText: 1,
              relativeDelay: 1,
              position: .init(x: x(from: 0.1), y: y(from: 0.65)),
              size: .init(width: 100, height: 60)),
    
        .init(event: .init(title: "Called Mom",
                           color: .blue),
              indexOfText: 1,
              relativeDelay: 1.5,
              position: .init(x: x(from: 0.45), y: y(from: 0.85)),
              size: .init(width: 150, height: 25)),
        
        
        .init(event: .init(title: "Katleyn's College Graduation",
                           tag: "Family Event",
                           startTime: .now,
                           endTime: .now + Constants.HourTime * 4,
                           color: .red),
              indexOfText: 2,
              relativeDelay: 0,
              position: .init(x: x(from: 0.5), y: y(from: 0.05)),
              size: .init(width: 150, height: 250)),
        
        .init(event: .init(title: "Chrismas Dinner",
                           tag: "Family Event",
                           startTime: .now,
                           endTime: .now + Constants.HourTime * 2,
                           color: .orange),
              indexOfText: 2,
              relativeDelay: 1,
              position: .init(x: x(from: 0.05), y: y(from: 0.6)),
              size: .init(width: 150, height: 150)),
        
            .init(event: .init(title: "Chrismas Dinner",
                               tag: "Family Event",
                               color: .purple),
                  indexOfText: 2,
                  relativeDelay: 1.5,
                  position: .init(x: x(from: 0.45), y: y(from: 0.85)),
                  size: .init(width: 150, height: 65)),
    ] }
    
//    MARK: Vars
    private let timingInterval: Double = 4
    
    let geo: GeometryProxy
    
    init(in geo: GeometryProxy) {
        self.geo = geo
    }
    
    
//    MARK: body
    var body: some View {
            
        ZStack {
            ForEach( 0..<events.count, id: \.self ) {  i in
                let model = events[i]
                let relativeDelay: Double = Double(model.indexOfText) * timingInterval + model.relativeDelay
                let dissapearDelay: Double = Double(model.indexOfText + 1) * timingInterval
                
                AboutScreenEventView(event: model.event,
                                     size: model.size,
                                     position: model.position,
                                     relatvieDelay: relativeDelay,
                                     dissapearDelay: dissapearDelay
                
                )
            }
            
            VStack {
                ForEach( 0..<texts.count, id: \.self ) { i in
                    let text = texts[i]
                    AboutScreenTextBlock(text: text,
                                         delay: Double(i) * timingInterval,
                                         timingInterval: timingInterval)
                    .padding(.bottom)
                    
                }
            }.frame(width: 250)
        }
    }
}


//MARK: AboutScreenTextBlock
struct AboutScreenTextBlock: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let text: String
    let delay: Double
    
    let timingInterval: Double
    
    @State private var isVisible: Bool = false
    
    var body: some View {
        
        VStack {
            if isVisible {
                UniversalText( text, size: Constants.UISubHeaderTextSize + 4, font: Constants.mainFont, textAlignment: .center )
                    .transition(.blurReplace)
                
                    .shadow(color: Colors.getBase(from: colorScheme),
                            radius: 5)
                
            }
        }.task {
            await RecallModel.wait(for: delay)
            withAnimation { isVisible = true }
        }
    }
}


#Preview {
//    let event = RecallWidgetCalendarEvent(title: "Texted Ben",
//                                          notes: "",
//                                          tag: "Texting a Friend",
//                                          startTime: .now,
//                                          endTime: .now + Constants.HourTime,
//                                          color: .red)
//    
//    AboutScreenEventView(event: event, position: .init(x: 050, y: 400))
    
//    AboutScreenView()
    
    OnBoardingBackgroundView()

}
