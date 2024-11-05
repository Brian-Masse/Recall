//
//  RecallCalendarEventImageStore.swift
//  Recall
//
//  Created by Brian Masse on 10/30/24.
//

import Foundation
import SwiftUI

class RecallCalendarEventImageStore: ObservableObject {
    
    private var imageIndexTable: Dictionary<String, Int> = [:]
    
    @Published private(set) var imageStore: [[ UIImage ]] = []
    
    private let maxStoreSize: Int = 10
    
    static let shared = RecallCalendarEventImageStore()
    
//    MARK: DecodeImages
//    asyncrounously decodes images and stores them in the store
//    This is used when loading the images on the CalendarEventView
    @MainActor
    func decodeImages(for event: RecallCalendarEvent) async -> [UIImage] {
        
        if let index = self.imageIndexTable[event.identifier()] {
            return imageStore[index]
        } else {
            
            var images: [UIImage] = []
            
            for imageData in event.images {
                if let uiImage = PhotoManager.decodeUIImage(from: imageData) {
                    images.append(uiImage)
                }
            }
            
            if imageStore.count >= maxStoreSize {
                imageStore.removeFirst()
            }
            
            imageStore.append(images)
            imageIndexTable[event.identifier()] = imageStore.count - 1
            
            return images
        }
    }
}
