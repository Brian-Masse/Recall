//
//  RecallCalendarEventImageStore.swift
//  Recall
//
//  Created by Brian Masse on 10/30/24.
//

import Foundation
import SwiftUI

//this stores a limitted number of the decoded image data from events
//it is written whe opening the calendarCreationView and CalendarEventView
//it is read to save time on the decoding process
class RecallCalendarEventImageStore: ObservableObject {
    
    private var imageStoreSize: Int = 0
    @Published private(set) var imageStore: Dictionary<String, [ UIImage ]> = [:]
    
    private let maxStoreSize: Int = 3
    
    static let shared = RecallCalendarEventImageStore()
    
//    MARK: DecodeImages
//    asyncrounously decodes images and stores them in the store
//    This is used when loading the images on the CalendarEventView
    @MainActor
    func decodeImages(for event: RecallCalendarEvent, expectedCount: Int ) async -> [UIImage] {
        
        let id = event.identifier()
        
        if event.images.isEmpty { return [] }
        
//        check to see if the images have already been decoded
//        if they have, retrieve them and avoid the decode process
        if let images = self.imageStore[id] {
            if images.count == expectedCount { return images }
        }
        
//        decode the images
        var images: [UIImage] = []
        for imageData in event.images {
            if let uiImage = PhotoManager.decodeUIImage(from: imageData) {
                images.append(uiImage)
            }
        }
        
        if imageStoreSize >= maxStoreSize {
            imageStore[id] = nil
            imageStoreSize -= 1
        }
        
        imageStore[id] = images
        imageStoreSize += 1
        
        return images
    }
}
