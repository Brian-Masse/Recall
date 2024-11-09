//
//  StyledPhotoPicker.swift
//  Recall
//
//  Created by Brian Masse on 10/22/24.
//

import Foundation
import SwiftUI
import UIUniversals
import PhotosUI

//MARK: PhotoPickerModifier
struct PhotoPickerModifier: ViewModifier {
    
    @ObservedObject var viewModel = StyledPhotoPickerViewModel.shared
    
    func body(content: Content) -> some View {
        content
            .photosPicker(isPresented: $viewModel.showingPhotoPicker,
                          selection: $viewModel.photoPickerItems,
                          maxSelectionCount: viewModel.imageCount,
                          selectionBehavior: .continuousAndOrdered,
                          matching: .images)
            .onChange(of: viewModel.photoPickerItems) { oldVal, newVal in
                if !viewModel.showingPhotoPicker { return }
                Task { await viewModel.loadPhotoPickerItems(oldValue: oldVal) }
            }
            .onAppear { viewModel.clear() }
            .onDisappear { viewModel.clear() }
    }
}

extension View {
    func photoPickerModifier() -> some View {
        modifier(PhotoPickerModifier())
    }
}

//MARK: StyledPhotoPickerCarousel
//This is just the carousel that shows the photos the user has selected
//it is a seperate struct so if a view (calendarEventCreationView) wants to use the toggle and caoursel seperatley it can
struct StyledPhotoPickerCarousel: View {
    
    @ObservedObject var viewModel = StyledPhotoPickerViewModel.shared
    
    private var imageHeight: Double {
        viewModel.selectedImages.count == 1 ? 275 : 200
    }
    
    @ViewBuilder
    private func makePhotoPreview(_ image: UIImage, allowsRemoval: Bool = true) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultTextSize))
            
            if allowsRemoval {
                UniversalButton {
                    RecallIcon("xmark")
                        .font(.callout)
                        .padding(7)
                        .background {
                            Circle().opacity(0.5).foregroundStyle(.background)
                        }
                        .padding(7)
                } action: { viewModel.removePhoto(image) }
            }
        }
        .onTapGesture { viewModel.showingPhotoPicker = true }
        .transition(.blurReplace)
    }
    
    @ViewBuilder
    private func makePhotoLoadingPreview() -> some View {
        RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
            .universalStyledBackgrond(.secondary, onForeground: true)
            .overlay { ProgressView() }
            .aspectRatio(2/3, contentMode: .fit)
            .frame(height: imageHeight)
    }
    
//    MARK: Body
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                if viewModel.photoPickerItems.count >= viewModel.selectedImages.count {
                    ForEach( 0..<viewModel.photoPickerItems.count, id: \.self) { i in
                        if i < viewModel.selectedImages.count {
                            let image = viewModel.selectedImages[i]
                            makePhotoPreview(image)
                        } else {
                            makePhotoLoadingPreview()
                        }
                    }
                } else {
                    
                    ForEach( viewModel.selectedImages, id: \.self ) { image in
                        makePhotoPreview(image, allowsRemoval: false)
                    }
                }
            }
            .frame(height: viewModel.photoPickerItems.count == 0 && viewModel.selectedImages.count == 0 ? 0 : imageHeight)
        }
        .mask(RoundedRectangle(cornerRadius: Constants.UIDefaultTextSize))
    }
}

//MARK: StyledPhotoPickerToggle
struct StyledPhotoPickerToggles: View {
    
    @ObservedObject private var viewModel = StyledPhotoPickerViewModel.shared
    @State private var showingCamera = false
    
    @ViewBuilder
    private func makeButton(icon: String, action: @escaping () -> Void) -> some View {
        UniversalButton {
            HStack {
                Spacer()
                
                RecallIcon(icon)
                
                Spacer()
            }
            .foregroundStyle(.foreground)
            .rectangularBackground(style: .secondary)
        } action: { action() }
    }
    
    @ViewBuilder
    private func makeTabBar() -> some View {
        HStack {
            makeButton(icon: "photo.on.rectangle") { viewModel.showingPhotoPicker = true }
            
            makeButton(icon: "camera") { showingCamera = true }
        }
    }
    
    var body: some View {
        if viewModel.selectedImages.count == 0 {
            makeTabBar()
                .transition(.blurReplace)
                .sheet(isPresented: $showingCamera) {
                    ImagePickerView(sourceType: .camera) { uiImage in
                        self.viewModel.selectedImages = [uiImage]
                    }.ignoresSafeArea()
                }
        }
    }
}

//MARK: StyledPhotoPicker
struct StyledPhotoPicker: View {
    
    @ObservedObject var photoManager = PhotoManager.shared
    @ObservedObject var viewModel = StyledPhotoPickerViewModel.shared
    
//    MARK: Vars
    @State private var showingPhotoPicker: Bool = false
    @State private var showingCamera: Bool = false
    
    private let imageHeight: Double = 200

    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( "Add Photos", size: Constants.formQuestionTitleSize, font: Constants.titleFont )
            
            StyledPhotoPickerToggles()
            
            StyledPhotoPickerCarousel()
        }
    }
}

//MARK: TempView
private struct TempView: View {
    
    @State private var image: UIImage?
    
    var body: some View {
        StyledPhotoPicker()
    }
}

#Preview {
    
    TempView()
}
