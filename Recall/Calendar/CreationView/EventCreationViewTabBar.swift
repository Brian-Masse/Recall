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
    
    @Binding var link: URL?
    @State private var showingLinkField = false
    
    @Binding var location: LocationResult?
    @State private var showingLocationPicker = false
    
    @ObservedObject private var viewModel = StyledPhotoPickerViewModel.shared
    
    @Namespace private var tabBarNamespace
    
    private func getPhotoPickerToggleWidth(in geo: GeometryProxy) -> Double {
        if showingLinkField && location != nil { return geo.size.width }
        if showingLinkField || location != nil { return (geo.size.width * (2/3)) }
        return (geo.size.width / 2)
    }
    
    private var showToolBar: Bool {
        !(link != nil && location != nil && !viewModel.selectedImages.isEmpty)
    }
    
    private var showPreviews: Bool {
        link != nil || showingLinkField || location != nil || !viewModel.selectedImages.isEmpty
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
                
                if link == nil && !showingLinkField {
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
        StyledPhotoPickerCarousel()
        if !viewModel.selectedImages.isEmpty {
            makeDataPreview(icon: "text.below.photo", data: "photos")
        }
        
        if showingLinkField || link != nil {
            StyledURLField("", binding: $link, prompt: "Add an optional Link")
                .padding(.leading, link == nil ? 0 : 15)
                .transition(.blurReplace)
        }
        
        if location != nil {
            UniversalButton {
                makeDataPreview(icon: "location", data: location!.title)
            } action: { showingLocationPicker = true }
        }
    }
    
    //    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            if showToolBar {
                makeToolRibbon()
            }

            if showPreviews {
                makeDataPreviews()
            }
        }
        .photoPickerModifier()
        .sheet(isPresented: $showingLocationPicker) {
            StyledLocationPicker($location, title: "select a location")
        }
    }
}

#Preview {
    EventCreationViewTabBar(link: .constant(nil),
                            location: .constant(nil))
}
