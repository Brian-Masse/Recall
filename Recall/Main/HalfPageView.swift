//
//  HalfPageView.swift
//  Recall
//
//  Created by Brian Masse on 10/25/23.
//

import Foundation
import SwiftUI


struct HalfPageView<Content: View>: View {
    
//    MARK: Vars
//    This is the master switch for whether or not the pop up is showing
    @State var showingEditorView: Bool = true
    
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
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func pageHeader() -> some View {
        HStack {
            UniversalText( title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            
            Spacer()
            
            LargeRoundedButton("", icon: showingEditorView ? "arrow.down" : "arrow.up", wide: false) {
                withAnimation { showingEditorView.toggle() }
            }
            
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
                    if showingEditorView {
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
                .frame(height: showingEditorView ? geo.size.height * (2/5) : geo.size.height * (1/10))
                .secondaryOpaqueRectangularBackground()
                .shadow(color: .black.opacity(0.5), radius: 10, y: 15)
            }
        }
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
                    if value { withAnimation { showing = true } }
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

