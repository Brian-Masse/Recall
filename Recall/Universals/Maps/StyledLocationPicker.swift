//
//  StyledLocationPicker.swift
//  Recall
//
//  Created by Brian Masse on 10/1/24.
//

import Foundation
import SwiftUI
import UIUniversals
import MapKit

//MARK: StyledLocationPicker
struct StyledLocationPicker: View {
    
    @State private var searchResults = [LocationResult]()
    @Binding private var selectedLocation: LocationResult?
    
    private let title: String
    
    @State private var showingSearchView: Bool = false
    @Binding private var showingFullScreen: Int
    
    @State private var position = MapCameraPosition.automatic
    @Namespace private var mapNameSpace
    
    @State private var inFullScreen: Bool = false
    
    init( _ location: Binding<LocationResult?>,
          title: String,
          showingFullScreen: Binding<Int> = Binding { -1 } set: { _ in }
 ) {
        self._selectedLocation = location
        self.title = title
        self._showingFullScreen = showingFullScreen
    }
    
//    MARK: Map
    @ViewBuilder
    private func makeMap() -> some View {
        Map(position: $position, scope: mapNameSpace) {
            if let location = searchResults.first?.location {
                Marker(coordinate: location) {
                    Image(systemName: "mappin")
                }
            }
        }
        .onTapGesture { showingFullScreen = (showingFullScreen == -1 ? 3 : -1 ) }
    }
    
//    MARK: Header
    @ViewBuilder
    private func makeLocationTitle() -> some View {
        if let selectedLocation {
            UniversalText( selectedLocation.title, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
        }
    }
    
//    MARK: Layouts
    @ViewBuilder
    private func makeCondensedLayout() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            
            UniversalText( title, size: Constants.formQuestionTitleSize, font: Constants.titleFont )
            makeLocationTitle()
            
            makeMap()
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
            
            StyledLocationSearchView(searchResults: $searchResults, inFullScreen: $inFullScreen)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func makeFullLayout() -> some View {
        ZStack(alignment: .topLeading) {
            makeMap()
            
            HStack {
                VStack(alignment: .leading) {
                    UniversalText( title, size: Constants.formQuestionTitleSize, font: Constants.titleFont )
                    makeLocationTitle()
                }
                Spacer()
            }
            .padding(.bottom)
            .background(.thinMaterial)
            
            StyledLocationSearchView(searchResults: $searchResults, inFullScreen: $inFullScreen)
                .shadow(color: .black.opacity(0.2), radius: 15, y: 10)
            
        }
    }
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            if inFullScreen {
                makeFullLayout()
            } else {
                makeCondensedLayout()
            }
        }
        .overlay {
            
            Text(inFullScreen ? "Full Screen" : "Condensed")
                .background(.red)
                .onTapGesture {
                    withAnimation { inFullScreen.toggle() }
                }
            
        }
        .onChange(of: selectedLocation) {
            showingSearchView = selectedLocation == nil
            if let selectedLocation {
                position = .camera(.init(centerCoordinate: selectedLocation.location,
                                                          distance: 5000))
            }
        }
        .onChange(of: searchResults) {
            if let firstResult = searchResults.first, searchResults.count == 1 {
                withAnimation {
                    selectedLocation = firstResult
                }
            }
        }
    }
}


//MARK: StyledLocationSearchView
private struct StyledLocationSearchView: View {
    
    @State private var locationService = LocationService(completer: .init())
    @Binding var searchResults: [LocationResult]
    
    @State private var showingSearchResults: Bool = false
    @State private var searchString = ""
    
    @Binding var inFullScreen: Bool
    
    private func didTapOnCompletion(_ completion: SearchCompletions) {
        Task {
            if let singleLocation = try? await locationService.search(with: "\(completion.title) \(completion.subTitle)").first {
                searchResults = [singleLocation]
            }
        }
        
        withAnimation { showingSearchResults = false }
    }
    
    private func getUserLocation() {
        if let locationResult = LocationManager.shared.getLocationInformation() {
            self.searchResults = [ locationResult ]
        }
    }
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeLocationItem(_ completion: SearchCompletions) -> some View {
        UniversalButton {
            HStack {
                VStack(alignment: .leading) {
                    UniversalText(completion.title, size: Constants.UIDefaultTextSize + 3, font: Constants.titleFont )
                    UniversalText(completion.subTitle, size: Constants.UISmallTextSize, font: Constants.mainFont)
                }
                
                Spacer()
                
                if let url = completion.url {
                    Link(destination: url) { RecallIcon("arrow.up.forward.circle.dotted").font(.title2) }
                }
            }
        } action: { didTapOnCompletion(completion) }
    }
    
    @ViewBuilder
    private func makeTextField() -> some View {
        
        let showingToggle = !locationService.completions.isEmpty
        
        HStack(spacing: 7) {
            StyledTextField(title: "", binding: $searchString, prompt: "Search")
                .onSubmit {
                    Task {
                        searchResults = (try? await locationService.search(with: searchString)) ?? []
                        print("running, \([searchResults.count])")
                    }
                }
            
            UniversalButton {
                RecallIcon("location.fill.viewfinder")
                    .rectangularBackground(style: .secondary)
            } action: { getUserLocation() }

        
            if showingToggle {
                UniversalButton { RecallIcon( showingSearchResults ? "chevron.up" : "chevron.down") }
                action: { showingSearchResults.toggle() }
                    .padding(7)
            }
        }
    }
    
//    MARK: Body
    var body: some View {
     
        VStack(spacing: 0) {
            
            if inFullScreen { Spacer() }
            
            VStack {
                makeTextField()
                
                ZStack {
                    Rectangle()
                        .foregroundStyle(.clear)
                    
                    if showingSearchResults {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 10) {
                                ForEach( locationService.completions ) { completion in
                                    makeLocationItem(completion)
                                    
                                    Divider()
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                        .rectangularBackground(style: .secondary)
                    }
                }
                .frame(height: inFullScreen ? 300: 0)
            }
            .background { if inFullScreen {
                Rectangle().foregroundStyle(.thinMaterial)
            } }
        }
        .border(.green)
        
        .onChange(of: searchString) {
            locationService.update(queryFragment: searchString)
            withAnimation { showingSearchResults = !searchString.isEmpty }
        }
        .onAppear { getUserLocation() }
//        .presentationDetents([.fraction(1/3), .large])
//        .presentationBackground(.regularMaterial)
//        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
}

private struct StyledLocationSearchDemoView: View {
    
    @State private var text: String = ""
    
    @State private var location: LocationResult? = nil
    
    var body: some View {
//        StyledTextField(title: "test", binding: $text)
//        ScrollView {
            StyledLocationPicker($location, title: "Event Location")
//                .border(.blue)
//        }
//        .border(.red)
    }
}

#Preview {
    
//    StyledLocationSearchView()
//    StyledLocationPicker()
    StyledLocationSearchDemoView()
}
