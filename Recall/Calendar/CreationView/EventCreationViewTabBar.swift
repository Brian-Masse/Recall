//
//  EventCreationViewTabBar.swift
//  Recall
//
//  Created by Brian Masse on 10/23/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct EventCreationViewTabBar: View {
    
    @State private var link: URL? = nil
    @State private var showingLinkField = false
    
    @State private var showingLocationPicker = false
    @State private var location: LocationResult? = nil
    
    @ObservedObject private var viewModel = StyledPhotoPickerViewModel.shared
    
    @Namespace private var tabBarNamespace
    
    private func getPhotoPickerToggleWidth(in geo: GeometryProxy) -> Double {
        if showingLinkField && location != nil { return .infinity }
        if showingLinkField || location != nil { return (geo.size.width * (2/3)) }
        return (geo.size.width / 2)
    }
    
    private var showToolBar: Bool {
        !(showingLinkField && location != nil && !viewModel.selectedImages.isEmpty)
    }
    
//    MARK: Button
    @ViewBuilder
    private func makeButton(_ icon: String, action: @escaping () -> Void ) -> some View {
        UniversalButton {
            HStack {
                Spacer()
                RecallIcon(icon)
                Spacer()
            }
            .rectangularBackground(style: .secondary)
            .transition(.blurReplace)
        } action: { action() }

    }
    
    @ViewBuilder
    private func makeDataPreview(icon: String, data: String) -> some View {
        HStack {
            RecallIcon(icon)
            
            UniversalText( data, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
        }
        .opacity(0.75)
        .padding(.leading)
    }
    
//    MARK: Ribbon
    @ViewBuilder
    private func makeToolRibbon() -> some View {
        GeometryReader { geo in
            
            let photoPickerToggleWidth = getPhotoPickerToggleWidth(in: geo)
            
            HStack {
                StyledPhotoPickerToggles()
                    .frame(width: photoPickerToggleWidth)
                
                if !showingLinkField {
                    makeButton("link") {
                        showingLinkField = true
                    }
                }
                
                if location == nil {
                    makeButton("location") {
                        showingLocationPicker = true
                    }
                }
            }
        }
        .frame(height: 50)
    }
    
//    MARK: Preview
    @ViewBuilder
    private func makeDataPreviews() -> some View {
        if showingLinkField {
            StyledURLField("", binding: $link, prompt: "Add an optional Link")
                .transition(.blurReplace)
        }
        
        if location != nil {
            UniversalButton {
                makeDataPreview(icon: "location", data: location!.title)
            } action: { showingLocationPicker = true }
                
        }
        
        if !viewModel.selectedImages.isEmpty {
            makeDataPreview(icon: "text.below.photo", data: "photos")
        }
        StyledPhotoPickerCarousel()
    }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            if showToolBar {
                makeToolRibbon()
            }

            makeDataPreviews()
        }
        .sheet(isPresented: $showingLocationPicker) {
            StyledLocationPicker($location, title: "select a location")
        }
    }
}


#Preview {
    EventCreationViewTabBar()
}
