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
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchResults = [LocationResult]()
    @Binding private var selectedLocation: LocationResult?
    
    @State private var inSearchField: Bool = false
    
    private let title: String
    
    @State private var position = MapCameraPosition.automatic
    @Namespace private var mapNameSpace
    
    init( _ location: Binding<LocationResult?>, title: String ) {
        self._selectedLocation = location
        self.title = title
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
        .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
    }
    
//    MARK: Header
    @ViewBuilder
    private func makeLocationTitle() -> some View {
        if let selectedLocation {
            UniversalText( selectedLocation.title, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
        }
    }
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            VStack(alignment: .leading, spacing: 7) {
                UniversalText( title, size: Constants.formQuestionTitleSize, font: Constants.titleFont )
                makeLocationTitle()
            }
            
            if !inSearchField { makeMap() }
            
            StyledLocationSearchView(searchResults: $searchResults, inSearch: $inSearchField)
            
            if selectedLocation != nil {
                UniversalButton {
                    HStack {
                        Spacer()
                        
                        UniversalText( "Done", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                        
                        RecallIcon("checkmark")
                        
                        Spacer()
                    }
                    .foregroundStyle(.black)
                    .rectangularBackground(style: .accent)
                } action: { dismiss() }
            }

        }
        
        
        .onChange(of: selectedLocation) {
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
        .padding(.bottom)
        .padding()
        .universalBackground()
        .ignoresSafeArea()
    }
}


//MARK: StyledLocationSearchView
private struct StyledLocationSearchView: View {
    
    @State private var locationService = LocationService(completer: .init())
    @Binding var searchResults: [LocationResult]
    
    @Binding var inSearch: Bool
    @State private var showingSearchResults: Bool = false
    @State private var searchString = ""
    
    private var searchResultsHeight: Double {
        inSearch ? .infinity : ( showingSearchResults ? 300 : 0 )
    }
    
    private func didTapOnCompletion(_ completion: SearchCompletions) {
        Task {
            if let singleLocation = try? await locationService.search(with: "\(completion.title) \(completion.subTitle)").first {
                searchResults = [singleLocation]
            }
        }
        
        self.searchString = completion.title
        
        withAnimation {
            inSearch = false
            showingSearchResults = false
        }
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
    
//    MARK: TextField
    @ViewBuilder
    private func makeTextField() -> some View {
        
        let showingToggle = !locationService.completions.isEmpty
        
        HStack(spacing: 7) {
            StyledTextField(title: "", binding: $searchString, prompt: "Search", isFocussed: $inSearch)
                .onSubmit {
                    Task { searchResults = (try? await locationService.search(with: searchString)) ?? [] }
                }
            
            UniversalButton {
                RecallIcon("location.fill.viewfinder")
                    .rectangularBackground(style: .secondary)
            } action: { getUserLocation() }

        
            if showingToggle {
                UniversalButton {
                    RecallIcon( showingSearchResults ? "chevron.down" : "chevron.up")
                        .rectangularBackground(style: .primary)
                }
                action: {
                    if inSearch { inSearch = false }
                    else { showingSearchResults.toggle() }
                }
            }
        }
    }
    
//    MARK: Results
    @ViewBuilder
    private func makeResults() -> some View {
        if locationService.completions.isEmpty {
            Rectangle()
                .foregroundStyle(.clear)
                .overlay(alignment:  .top) {
                    UniversalText( "Begin Typing to See Results", size: Constants.UISmallTextSize, font: Constants.mainFont )
                        .opacity(0.75)
                }
                
            
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach( locationService.completions ) { completion in
                        makeLocationItem(completion)
                        
                        Divider()
                    }
                }
            }
        }
    }
    
//    MARK: Body
    var body: some View {
     
        VStack(spacing: 0) {
            makeTextField()

            ZStack {
                if showingSearchResults {
                    makeResults()
                        .rectangularBackground(style: .secondary)
                        .transition(.blurReplace())
                        .padding(.top, 7)
                }
            }.frame(maxHeight: searchResultsHeight)
        }
        .onChange(of: inSearch) { withAnimation {
            if inSearch { showingSearchResults = true }
        } }
        .onChange(of: searchString) {
            locationService.update(queryFragment: searchString)
            withAnimation { showingSearchResults = !searchString.isEmpty }
        }
        .onAppear { getUserLocation() }
        .ignoresSafeArea()
    }
}

//MARK: Preview
private struct StyledLocationSearchDemoView: View {
    
    @State private var text: String = ""
    @State private var location: LocationResult? = nil
    
    var body: some View {
        StyledLocationPicker($location, title: "Event Location")
    }
}

#Preview {
    StyledLocationSearchDemoView()
}
