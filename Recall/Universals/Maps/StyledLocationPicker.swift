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
    
    @State private var position = MapCameraPosition.automatic
    
    init( _ location: Binding<LocationResult?>, title: String ) {
        self._selectedLocation = location
        self.title = title
    }
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeMap() -> some View {
        Map(position: $position, selection: $selectedLocation) {
            ForEach(searchResults) { result in
               Marker(coordinate: result.location) {
                   Image(systemName: "mappin")
               }
               .tag(result)
           }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
    }
    
    @ViewBuilder
    private func makeLocationTitle() -> some View {
        if let selectedLocation {
            UniversalText( selectedLocation.title, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
        }
    }
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            UniversalText( title, size: Constants.formQuestionTitleSize, font: Constants.titleFont )
            makeLocationTitle()
            
            makeMap()
            
            StyledLocationSearchView(searchResults: $searchResults)
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
}


//MARK: StyledLocationSearchView
private struct StyledLocationSearchView: View {
    
    @State private var locationService = LocationService(completer: .init())
    @Binding var searchResults: [LocationResult]
    
    @State private var showingSearchResults: Bool = false
    @State private var searchString = ""
    
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
                    Task { searchResults = (try? await locationService.search(with: searchString)) ?? [] }
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
    
    @ViewBuilder
    private func clearSearch() -> some View {
        
    }
    
    
//    MARK: Body
    var body: some View {
     
        VStack(spacing: 10) {
            
            makeTextField()
            
            if showingSearchResults {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach( locationService.completions ) { completion in
                            makeLocationItem(completion)
                            
                            Divider()
                        }
                    }
                }
                .rectangularBackground(style: .secondary)
            }
                
        }
        .onChange(of: searchString) {
            locationService.update(queryFragment: searchString)
            withAnimation { showingSearchResults = !searchString.isEmpty }
        }
        
        .onAppear {
            getUserLocation()
        }
//        .presentationDetents([.fraction(1/3), .large])
//        .presentationBackground(.regularMaterial)
//        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
    
}

private struct StyledLocationSearchDemoView: View {
    
    @State private var text: String = ""
    
    @State private var location: LocationResult? = nil
    
    var body: some View {
        StyledTextField(title: "test", binding: $text)
        
        StyledLocationPicker($location, title: "Event Location")
    }
}

#Preview {
    
//    StyledLocationSearchView()
//    StyledLocationPicker()
    StyledLocationSearchDemoView()
}
