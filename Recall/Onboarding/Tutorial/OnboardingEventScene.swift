//
//  OnboardingEventScene.swift
//  Recall
//
//  Created by Brian Masse on 12/31/24.
//

import Foundation
import SwiftUI
import UIUniversals

private let titleEventFocus: OnboardingEventScene.EventFocus = .init(
    0,
    title: "Overview",
    type: "",
    icon: "calendar",
    description: OnboardingSceneUIText.eventsSceneInstructionText
)

private let sampleEventFoucsses: [OnboardingEventScene.EventFocus] = [
    .init(
        1,
        title: "Going for a Run",
        type: "Title",
        icon: "widget.small",
        description: "You name events just like you name events on any other calendar"
    ),
    
    .init(
        2,
        title: "5.2 miles",
        type: "Notes",
        icon: "text.justify.left",
        description: "Offer additional context and significance to your events"
    ),
    
    .init(
        3,
        title: "7:45 - 8:45 AM",
        type: "Time",
        icon: "clock",
        description: "Shows when this event happened"
    ),
    
    .init(
        4,
        title: "Exercise",
        type: "Tag",
        icon: "tag",
        description: "Categorizes the event and automatically counts it towards your various goals"
    ),
    
    .init(
        5,
        title: "Reading, MA",
        type: "Location",
        icon: "location",
        description: "Events can hold additional information, including photos, locations, or links"
    ),
    
    .init(
        6,
        title: "Get Started",
        type: "",
        icon: "line.diagonal.arrow",
        description: "Quickly Recall your first day to get a feel for how Recall works!"
    )
]


//MARK: OnboardingEventScene
struct OnboardingEventScene: View {
    
//    MARK: EventFocus
    struct EventFocus: Equatable, Identifiable {
        let id: Int
        let title: String
        let type: String
        let icon: String
        let description: String
        
        init(
            _ id: Int,
            title: String,
            type: String,
            icon: String,
            description: String
        ) {
            self.id = id
            self.title = title
            self.type = type
            self.icon = icon
            self.description = description
        }
    }
    
//    MARK: Vars
    @State private var eventFocusses: [EventFocus]
    @State private var currentFocus: EventFocus
    @State private var currentFocusIndex: Int = -1
    
    @State private var eventRotation: Double = 0
    @State private var xAxisRotation: Double = 0
    @State private var yAxisRotation: Double = 0
    @State private var zAxisRotation: Double = 0
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var viewModel = OnboardingViewModel.shared
    @Namespace private var namespace
    
    private var blur: Double {
        (currentFocusIndex >= 0 && currentFocusIndex < eventFocusses.count - 1) ? 4 : 0
    }
    
    init() {
        self.eventFocusses = sampleEventFoucsses
        self.currentFocus = titleEventFocus
    }
    
//    MARK: ViewMethods
    private func finishRotation() {
        eventRotation = 0
    }
    
    private func randomizeRotation() {
        xAxisRotation = Double.random(in: 0.75...1)
        yAxisRotation = Double.random(in: 0.75...1)
        zAxisRotation = Double.random(in: 0...0.5)
        eventRotation = Double.random(in: -13...13)
    }
    
    private func incrementFocus() {
        currentFocusIndex += 1
        currentFocus = eventFocusses[min(currentFocusIndex, eventFocusses.count - 1)]
        randomizeRotation()
        
        if currentFocusIndex == eventFocusses.count - 1 {
            viewModel.setSceneStatus(to: .complete)
            finishRotation()
        }
    }
    
//    MARK: makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack(alignment: .top) {
            RecallIcon(currentFocus.icon)
                .font(.title3)
                .padding(.top, 5)
            
            VStack(alignment: .leading) {
                UniversalText( currentFocus.title, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .matchedGeometryEffect(id: currentFocus.id,
                                           in: namespace,
                                           properties: .frame,
                                           isSource: true)
                
                if !currentFocus.type.isEmpty {
                    UniversalText( currentFocus.type, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                        .opacity(0.75)
                }
                
                UniversalText(currentFocus.description, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                    .opacity(0.75)
                    .padding(.trailing)
            }
        }
    }
    
    
//    MARK: makeFocussedText
    @ViewBuilder
    private func makeFocussedTextLabel(focus: EventFocus, title: Bool) -> some View {
        HStack {
            if !title { RecallIcon(focus.icon) }
            
            UniversalText(focus.title,
                          size: title ? Constants.UISubHeaderTextSize + 3 : Constants.UIDefaultTextSize,
                          font: title ? Constants.titleFont : Constants.mainFont)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func makeFocussedText(focus: EventFocus, title: Bool = false) -> some View {
        ZStack {
            if currentFocus != focus {
                makeFocussedTextLabel(focus: focus, title: title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .matchedGeometryEffect(id: focus.id, in: namespace)
                    .opacity(title ? 1 : 0.75)
                    .blur(radius: blur)
                
            } else {
                makeFocussedTextLabel(focus: focus, title: title)
            }
        }
        .foregroundStyle(Colors.getAccent(from: colorScheme).safeMix(with: .black,
                                            by: colorScheme == .light ? 0.5 : 0))
        .onTapGesture { withAnimation(.bouncy) {
            self.currentFocus = focus
        } }
    }
    
    
//    MARK: makeContent
    @ViewBuilder
    private func makeContent() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<eventFocusses.count - 1, id: \.self) { i in
                let focus = eventFocusses[i]
                makeFocussedText(focus: focus, title: i == 0)
            }
        }
    }
    
//    MARK: makeEvent
    @ViewBuilder
    private func makeEvent() -> some View {
        HStack(alignment: .top, spacing: 7) {
            RoundedRectangle(cornerRadius: Constants.UIDefaultTextSize)
                .universalStyledBackgrond(.accent, onForeground: true)
                .frame(width: 5)
                .blur(radius: blur)
            
            makeContent()
        }
            .padding()
            .background {
                Rectangle()
                    .universalStyledBackgrond(.accent, onForeground: true)
                    .opacity(0.25)
                    .background()
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
                    .shadow(color: .black.opacity(0.3), radius: 15, y: 10)
                    .blur(radius: blur)
            }
            .frame(width: 250, height: 350)
            .rotation3DEffect(.init(degrees: eventRotation),
                              axis: (xAxisRotation,
                                     yAxisRotation,
                                     zAxisRotation),
                              perspective: 0.2)
    }
    
//    MARK: makeContinueButton
    @ViewBuilder
    private func makeContinueButton() -> some View {
        UniversalButton {
            HStack {
                UniversalText( "Next", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                RecallIcon("arrow.turn.down.right")
            }
            .foregroundStyle(.black)
            .padding(.horizontal)
            .rectangularBackground(style: .accent)
            
        } action: { incrementFocus() }
            .opacity(currentFocusIndex < eventFocusses.count - 1 ? 1 : 0)
    }
    
    
//    MARK: Body
    var body: some View {
        OnboardingSplashScreenView(icon: "widget.small",
                                   title: "Events",
                                   message: OnboardingSceneUIText.eventsSceneIntroductionText) {
            VStack(spacing: 30) {
                Spacer()
                
                makeHeader()
                    .frame(width: 300)
                
                makeEvent()
                
                makeContinueButton()
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                OnboardingContinueButton()
            }
            .onAppear { viewModel.setSceneStatus(to: .hideButton) }
        }
    }
}

#Preview {
    OnboardingEventScene()
}
