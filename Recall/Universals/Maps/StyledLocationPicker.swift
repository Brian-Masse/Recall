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

struct StyledLocationPicker: View {
    @State private var position = MapCameraPosition.automatic

    
    @State private var showingSearchView: Bool = false
    
    var body: some View {
        VStack {
            Map(position: $position)
            
            Text("search")
                .onTapGesture { showingSearchView = true }
                .sheet(isPresented: $showingSearchView) {
                    StyledLocationSearchView()
                }
        }
    }
}
//
//MARK: StyledLocationSearchView
private struct StyledLocationSearchView: View {
    
    @State private var locationService = LocationService(completer: .init())
    @State private var searchString = "search here"
    
    var body: some View {
     
        VStack {
            StyledTextField(title: "", binding: $searchString)
         
            Spacer()
            
            List {
                ForEach( locationService.completions ) { completion in
                    VStack {
                        HStack {
                            Text(completion.title)
                            Spacer()
                            Text(completion.subTitle)
                        }
                        
                        if let url = completion.url {
                            Link(url.absoluteString, destination: url)
//                                .lineLimit(1)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        
        .onChange(of: searchString) { locationService.update(queryFragment: searchString) }
        
        
        .interactiveDismissDisabled()
        .presentationDetents([.fraction(1/3), .large])
        .presentationBackground(.regularMaterial)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
    
}

#Preview {
    
//    StyledLocationSearchView()
    StyledLocationPicker()
}
