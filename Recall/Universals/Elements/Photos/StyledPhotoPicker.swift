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

struct StyledPhotoPicker: View {
    
    @ObservedObject var photoManager = PhotoManager.shared
    
//    MARK: Vars
    @State private var selectedImages: [UIImage] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []
    
    @State private var showingPhotoPicker: Bool = false
    @State private var showingCamera: Bool = false
    
    private let imageCount: Int = 5
    private let imageHeight: Double = 200
    
    
//    MARK: LoadPhotos
    private func loadPhotoPickerItems() async {
        if !showingPhotoPicker { return }
        
        self.selectedImages.removeAll()
        
        for item in photoPickerItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    if !selectedImages.contains(uiImage) {
                        selectedImages.append( uiImage )
                    }
                }
            }
        }
    }
    
    private func removePhoto(_ image: UIImage) {
        if let index = selectedImages.firstIndex(of: image) {
            selectedImages.remove(at: index)
        
            photoPickerItems.remove(at: index)
        }
    }
    
//    MARK: PhotoPreview
    @ViewBuilder
    private func makePhotoPreview(_ image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultTextSize))
            
            UniversalButton {
                RecallIcon("xmark")
                    .padding(7)
                    .background {
                        Circle().opacity(0.5).foregroundStyle(.background)
                    }
                    .padding(7)
            } action: { removePhoto(image) }
        }
        .transition(.blurReplace)
    }
    
//    MARK: Carousel
    @ViewBuilder
    private func makePhotoCarousel() -> some View {
        ScrollView {
            LazyHStack(spacing: 10) {
                ForEach(selectedImages, id: \.self) { image in
                    makePhotoPreview(image)
                }
            }
        }
    }

//    MARK: TabBar
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
            makeButton(icon: "photo.on.rectangle") { showingPhotoPicker = true }
            
            makeButton(icon: "camera") { showingCamera = true }
        }
    }
    
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( "Add Photos", size: Constants.formQuestionTitleSize, font: Constants.titleFont )
            
            if selectedImages.count == 0 {
                makeTabBar()
                    .transition(.blurReplace)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach( selectedImages, id: \.self ) { uiImage in
                        makePhotoPreview(uiImage)
                    }
                }
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker,
                      selection: $photoPickerItems,
                      maxSelectionCount: imageCount,
                      selectionBehavior: .continuousAndOrdered,
                      matching: .images)
        
        .sheet(isPresented: $showingCamera) {
            ImagePickerView(sourceType: .camera) { uiImage in
                self.selectedImages = [uiImage]
            }.ignoresSafeArea()
        }
        
        .onChange(of: photoPickerItems) { Task { await loadPhotoPickerItems() } }
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
