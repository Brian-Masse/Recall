//
//  HalfPageView.swift
//  Recall
//
//  Created by Brian Masse on 10/25/23.
//

import Foundation
import SwiftUI


struct HalfPageView<Content: View>: View {
    
    enum PageExpansion: Double {
        case full
        case half
        case hide
        
        func getHeight() -> CGFloat {
            switch self {
            case .full: return 9/10
            case .half: return 2/5
            case .hide: return 3/20
            }
        }
        
        mutating func toggle() {
            switch self {
            case .hide: self = .half
            default: self = .hide
            }
        }
    }
    
//    MARK: Vars
//    This is the master switch for whether or not the pop up is showing
//    @State var showingEditorView: Bool = false
    @State var pageExpansion: PageExpansion = .hide
    
//    This is responsible for whether or not the display is showing or not
//    when updating this value, the presenter of this screen will automatically dismiss the view
    @Binding var presenting: Bool
    
    let title: String
    let content: Content
    
    init( isPresenting: Binding<Bool>, _ title: String, contentBuilder: () -> Content ) {
        self._presenting = isPresenting
        self.title = title
        self.content = contentBuilder()
    }
    
    private var drag: some Gesture {
        DragGesture()
            .onChanged { dragGesture in }
            .onEnded { dragGesture in
                if dragGesture.location.y < dragGesture.startLocation.y {
                    switch pageExpansion {
                    case .full: withAnimation { pageExpansion = .full }
                    case .half: withAnimation { pageExpansion = .full }
                    case .hide: withAnimation { pageExpansion = .half }
                    }
                } else {
                    switch pageExpansion {
                    case .full: withAnimation { pageExpansion = .hide }
                    case .half: withAnimation { pageExpansion = .hide }
                    case .hide: withAnimation { presenting = false }
                    }
                }
            }
    }
    
    private func tapGesture() {
        switch pageExpansion {
        case .full: withAnimation { pageExpansion = .hide }
        case .half: withAnimation { pageExpansion = .hide }
        case .hide: withAnimation { pageExpansion = .half }
        }
        
    }
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func pageHeader() -> some View {
        HStack {
            UniversalText( title, size: Constants.UIHeaderTextSize, font: Constants.titleFont, wrap: false, scale: true )
            
            Spacer()
            
//            LargeRoundedButton("", icon: pageExpansion != .hide ? "arrow.down" : "arrow.up", wide: false) {
//                withAnimation { pageExpansion.toggle() }
//            }
            
            LargeRoundedButton("", icon: "xmark", wide: false) {
                withAnimation { presenting = false }
            }
        }
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            VStack { 
                Spacer()
                
                VStack(alignment: .leading) {
                    pageHeader()
                        .padding()
                    if pageExpansion != .hide {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                content
                                    .padding( .horizontal, 5 )
                                    .padding(. bottom)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: geo.size.height * pageExpansion.getHeight())
                .opaqueRectangularBackground(0, stroke: true)
                .shadow(color: .black.opacity(0.4), radius: 10, y: -5)
            }
        }
        .gesture(drag)
        .onTapGesture { tapGesture() }
        .ignoresSafeArea()
    }
}


//MARK: ViewModifiers
//This is the publically accessible modifier that you attatch to a view that should present this half screen
private struct HalfPageScreen<C: View>: ViewModifier {
    
    @Environment(\.toggleScreenKey) var toggleScreen
    
    @Binding var presenting: Bool
    let title: String
    let content: C
    
    init( _ title: String, presenting: Binding<Bool>, contentBuilder: () -> C ) {
        self.title = title
        self._presenting = presenting
        self.content = contentBuilder()
    }
    
    func body( content: Content ) -> some View {
        
        ZStack {
            content
                .onChange(of: toggleScreen) { newValue in presenting = newValue }

            if presenting {
                Text("")
                    .opacity(0)
                    .preference(key: HalfScreenToggleKey.self, value: true)
                    .onAppear {
                        HalfPageScreenReceiver.title = title
                        HalfPageScreenReceiver.content = AnyView(self.content)
                    }
            } else {
//                if the view is dismissed from the child, this sends that intention up to the receiver
                Text("")
                    .opacity(0)
                    .preference(key: HalfScreenToggleKey.self, value: false)
            }
        }
    }
}

//this shoudl not be publically accessed
//there should be one instance of this on a high level view (ie. MainView) and is responsible
//for capturing the changing preferences and displaying the halfpage screen
private struct HalfPageScreenReceiver: ViewModifier {
    
    @Binding var showing: Bool
    
    static var title: String = ""
    static var content: AnyView? = nil
    
    func body(content: Content) -> some View {
        
        ZStack {
            content
                .onPreferenceChange(HalfScreenToggleKey.self) { value in
                    if value { withAnimation { showing = true } } else {
                        showing = false
                    }
                }
                .environment(\.toggleScreenKey, showing)
            
            if showing {
                HalfPageView(isPresenting: $showing, HalfPageScreenReceiver.title) { HalfPageScreenReceiver.content }
            } else {
                Text("")
                    .opacity(0)
                    .foregroundColor(.blue)
                    .frame(height: 200)
                    .preference(key: HalfScreenToggleKey.self, value: false)
            }
        }
    }
}

extension View {
    func halfPageScreen<C: View>( _ title: String, presenting: Binding<Bool>, contentBuilder: () -> C ) -> some View {
        modifier( HalfPageScreen(title, presenting: presenting, contentBuilder: contentBuilder) )
    }
    
    func halfPageScreenReceiver( showing: Binding<Bool> ) -> some View {
        modifier( HalfPageScreenReceiver(showing: showing) )
    }
}


//MARK: Environment
//This is used for sending data down from the receiver to the view presenting the halfPageView
//For some reason the child view does not always detect a preference key change
//so changing this environment var allows it capture when the view needs to be dismissed, and update the view that called it
private struct ToggleScreenKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var toggleScreenKey: Bool {
        get { self[ToggleScreenKey.self] }
        set { self[ToggleScreenKey.self] = newValue }
    }
}


//MARK: Preferences
//this is used for sending data up from a view that wants to present a halfscreen
//to the receiver that will actually present the screen on top of everything
struct HalfScreenToggleKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

