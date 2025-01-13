//
//  OnboardingOverviewEventAnimation.swift
//  Recall
//
//  Created by Brian Masse on 1/12/25.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - SampleEvents
private let sampleEvents : [RecallWidgetCalendarEvent] = [
    .init(title: "Gym", notes: "Push type 1", tag: "Exercise", color: .orange),
    .init(title: "Called Mom", notes: "", tag: "Family", color: .purple),
    .init(title: "Lunch with Friends", notes: "At Crafted; great time seeing some old friends", tag: "Exercise", color: .blue),
    .init(title: "working on HW", notes: "", tag: "hw", color: .green),
    
    .init(title: "Board Meeting", notes: "incredibly boring", tag: "meeting", color: .yellow),
    .init(title: "Listened to music", notes: "", tag: "extra", color: .red),
    .init(title: "Skipped math", notes: "", tag: "extra", color: .black),
    .init(title: "Debate practice", notes: "", tag: "debate", color: .green),
    
    .init(title: "Work on Recall", notes: "", tag: "code", color: .orange),
    .init(title: "Cooking Dinner", notes: "", tag: "cooking", color: .blue),
    .init(title: "building Legos", notes: "", tag: "extra", color: .red),
    .init(title: "Driving", notes: "", tag: "travelling", color: .orange),
    
    .init(title: "work on Planter", tag: "programmer"),
    .init(title: "playing celeste", tag: "video game"),
    .init(title: "playing RDR", tag: "vieo game"),
    .init(title: "Drawing", tag: "drawing"),
    .init(title: "Graphic Design", tag: "Art"),
    .init(title: "PhotoShoot", tag: "art"),
    .init(title: "sculpting", tag: "art"),
    .init(title: "pottery", tag: "art"),
    .init(title: "Went on Run", tag: "exercise"),
    .init(title: "Lifted", tag: "excercise"),
    .init(title: "Worked on projects", tag: "extra"),
    .init(title: "struggled to come up with this shit", tag: "extra"),
    .init(title: "Played basketball", tag: "exercise"),
    .init(title: "Went on a date", tag: "date"),
    .init(title: "Hanging with friends", tag: "hanging with friends"),
    .init(title: "Whooped Rowan in Smash", tag: "hanging with friends"),
    .init(title: "New years party", tag: "hanging with friends"),
    .init(title: "Making margs", tag: "hanging with friends"),
]


private extension CGPoint {
    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(x: x, y: y)
    }
}


//MARK: - OnboardingOverviewEventAnimation
struct OnboardingOverviewEventAnimation: View {
    
    static let animationDelay: Double = 1
    
//    MARK:  AnimatedEvent
    private struct AnimatedEvent {
        
        let appearanceDelay: Double
        var position: CGPoint
        let size: CGSize
        let event: RecallWidgetCalendarEvent
        
        init(
            _ index: Int,
            position: CGPoint,
            size: CGSize
        ) {
            self.appearanceDelay = Double(index) * OnboardingOverviewEventAnimation.animationDelay
            self.position = position
            self.size = size
            self.event = sampleEvents[index]
        }
        
        init(
            appearanceDelay: Double,
            position: CGPoint,
            size: CGSize,
            event: RecallWidgetCalendarEvent
        ) {
            self.appearanceDelay = appearanceDelay
            self.position = position
            self.size = size
            self.event = event
        }
    }
    
    
//    MARK: - Events
    @State private var events: [AnimatedEvent] = [
//        .init(0, position: .init(0, 0),
//              size: .init(width: 100, height: 100)),
        
        .init(0, position: .init(262.3333282470703, 491.6666564941406),
              size: .init(width: 120, height: 100)),
        
        .init(1, position: .init(22.666656494140625, 667.6666564941406),
              size: .init(width: 150, height: 50)),
        
        .init(2, position: .init(23, 131),
              size: .init(width: 130, height: 200)),
        
        .init(3, position: .init(247.0, 25.666656494140625),
              size: .init(width: 120, height: 150)),
        
        
        .init(4, position: .init(194.0, 227.0),
              size: .init(width: 200, height: 100)),
        .init(5, position: .init(57, 384),
              size: .init(width: 100, height: 240)),
        .init(6, position: .init(241, 618),
              size: .init(width: 100, height: 100)),
        .init(7, position: .init(79, 10),
              size: .init(width: 150, height: 120)),
        
        .init(8, position: .init(221, 345),
              size: .init(width: 130, height: 175)),
        .init(9, position: .init(32, 577),
              size: .init(width: 100, height: 150)),
        .init(10, position: .init(172, 140),
              size: .init(width: 150, height: 150)),
        .init(11, position: .init(163, 655),
              size: .init(width: 120, height: 150)),
        
    ]
    
//    MARK: - Vars
    @State private var t: Double = 100
    @State private var timer: Timer?
    
    @State private var selectedEventIndex: Int = 0
    
    @Binding var currentMaxTime: Double
    
    private func appendEvents() async {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .blue]
        var currentXPos: Double = 0
        var currentYPos: Double = 0
        
        let extraEvents: [AnimatedEvent] = sampleEvents.map { event in
            let width = Double.random(in: 75...200)
            let height = Double.random(in: 50...200)
            
            let xPos = currentXPos
            let yPos = currentYPos
            
            currentXPos = (currentXPos + width + 10).truncatingRemainder(dividingBy: 400)
            currentYPos = (currentYPos + height + 10).truncatingRemainder(dividingBy: 800)
            
            let color = colors.randomElement()!
            let eventCopy = RecallWidgetCalendarEvent(title: event.title,
                                                      tag: event.tag,
                                                      color: color)
            
            return .init(appearanceDelay: 3 * 4 * OnboardingOverviewEventAnimation.animationDelay - 0.01,
                         position: .init(xPos - 50, yPos - 50),
                         size: .init(width: width, height: height),
                         event: eventCopy)
        }
        
        events.append(contentsOf: extraEvents)
    }
    
    
//    MARK: MoveGesture
    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                events[selectedEventIndex].position = .init(x: value.location.x, y: value.location.y)
            }
            .onEnded { value in
                events[selectedEventIndex].position = .init(x: value.location.x, y: value.location.y)
                print("(\(Int(value.location.x)), \(Int(value.location.y)))")
            }
    }
    
//    MARK: - Body
    var body: some View {
        
        ZStack(alignment: .topLeading) {
            
            
            Rectangle()
                .foregroundStyle(.clear)
            
            ForEach( 0..<events.count, id: \.self ) { i in
                
                let event = events[i]
                let transitionOffset: Double = event.position.x < 200 ? -200 : 200
                
                if event.appearanceDelay < t && event.appearanceDelay < currentMaxTime {
                    WidgetEventView(event: event.event,
                                    height: event.size.height,
                                    showContent: true)
                    .frame(width: event.size.width)
                    
                    .alignmentGuide(.leading) { _ in -event.position.x }
                    .alignmentGuide(.top) { _ in -event.position.y }
                    
                    .opacity(selectedEventIndex == i ? 1 : 0.95)
                    .onTapGesture {
                        selectedEventIndex = i
                    }
                    
                    .transition( .asymmetric(insertion: .offset(y: 100).combined(with: .scale(scale: 0.75)).combined(with: .opacity),
                                             removal: .opacity.combined(with: .offset(x: transitionOffset)) ) )
                }
            }
        }
        .task {
            await appendEvents()
            await appendEvents()
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                withAnimation(.spring(duration: 0.75)) { t = min(t + 0.5, currentMaxTime) }
            }
        }
        
        .contentShape(Rectangle())
        .gesture(moveGesture)
    }
}
