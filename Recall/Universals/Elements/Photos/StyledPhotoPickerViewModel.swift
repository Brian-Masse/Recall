//
//  StyledPhotoPickerViewModel.swift
//  Recall
//
//  Created by Brian Masse on 10/23/24.
//

import Foundation
import SwiftUI
import PhotosUI

class StyledPhotoPickerViewModel: ObservableObject {
 
    @Published var selectedImages: [UIImage] = []
    @Published var photoPickerItems: [PhotosPickerItem] = []
    
    @Published var showingPhotoPicker: Bool = false
    
    let imageCount: Int = 5
    
    static let shared = StyledPhotoPickerViewModel()
    
//    MARK: class methods
    @MainActor
    func clear() {
        self.selectedImages = []
        self.photoPickerItems = []
        self.showingPhotoPicker = false
    }
    
//    this is called whenever there is a change in the photoPickerItems
    @MainActor
    func loadPhotoPickerItems(oldValue: [PhotosPickerItem]) async {
        if oldValue.count > photoPickerItems.count {
            self.selectedImages = []
        }
            
        for item in photoPickerItems {
            if (oldValue.count <= photoPickerItems.count) && oldValue.firstIndex(of: item) != nil { continue }
            
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    if !selectedImages.contains(uiImage) {
                        selectedImages.append( uiImage )
                    }
                }
            }
        }
    }
    
    func removePhoto(_ image: UIImage) {
        if let index = selectedImages.firstIndex(of: image) {
            selectedImages.remove(at: index)
        
            photoPickerItems.remove(at: index)
        }
    }
    
}
