//
//  RecallCalendarEvent.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import RealmSwift
import SwiftUI
import UIUniversals

class RecallCalendarEvent: Object, Identifiable, OwnedRealmObject  {
    
//    MARK: Vars
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
    @Persisted var title: String = ""
    @Persisted var notes: String = ""
    @Persisted var urlString: String = ""
    
    @Persisted var locationLongitude: Double = 0
    @Persisted var locationLatitude: Double = 0
    @Persisted var locationTitle: String = ""
    
    @Persisted var images: RealmSwift.List< Data > = List()
    
    @Persisted var isTemplate: Bool = false
    @Persisted var isFavorite: Bool = false
    
    @Persisted var startTime: Date = .now
    @Persisted var endTime:   Date = .now + Constants.HourTime
    
    @Persisted var category: RecallCategory? = nil
    @Persisted var goalRatings: RealmSwift.List< GoalNode> = List()
    
    private var cachedGoalRatings: RealmSwift.List<GoalNode> = List()
    
//    MARK: Convenience Vars
    func identifier() -> String { ownerID + title + startTime.formatted() + endTime.formatted() }
    
    func getURL() -> URL? { URL(string: self.urlString) }
    
//    MARK: Init
    @MainActor
    convenience init(ownerID: String,
                     title: String,
                     notes: String,
                     urlString: String,
                     location: LocationResult? = nil,
                     images: [UIImage] = [],
                     startTime: Date,
                     endTime: Date,
                     categoryID: ObjectId,
                     goalRatings: Dictionary<String, String>,
                     previewEvent: Bool = false) {
        self.init()
        self.ownerID = ownerID
        
        self.title = title
        self.notes = notes
        self.urlString = urlString
        
        self.startTime = startTime
        self.endTime = endTime
        
        if let location = location {
            self.locationTitle = location.title
            self.locationLongitude = location.location.longitude
            self.locationLatitude = location.location.latitude
        }
        
        let imageData = encodeImages(from: images)
        self.images = imageData
        
        if !previewEvent {
            if let retrievedCategory = RecallCategory.getCategoryObject(from: categoryID) { self.category = retrievedCategory }
            self.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
            
            RecallModel.shared.updateEvent(self, updateType: .insert)
        }
    }

//    MARK: Override Init
    @MainActor
    override init() {
        super.init()
        self.cachedGoalRatings = self.goalRatings
    }
    
//    MARK: - General Update
    var oldStartTime: Date = .now
    var oldEndTime: Date = .now
    var oldGoalRatings: [GoalNode] = []
    
    private func updateOldData(_ event: RecallCalendarEvent) {
        event.oldStartTime = self.startTime
        event.oldEndTime = self.endTime
        event.oldGoalRatings = Array(self.goalRatings)
    }
    
    @MainActor
    func update( title: String,
                 notes: String,
                 urlString: String,
                 startDate: Date,
                 endDate: Date,
                 location: LocationResult? = nil,
                 images: [UIImage],
                 tagID: ObjectId,
                 goalRatings: Dictionary<String, String>? = nil ) {
        
//        check if the user is updating the time of the event
        if ( startDate != startTime || endDate != endTime ) {
            updateTime(startDate: startDate, endDate: endDate)
        }
        
//        check if the user is updating the date of the event
        if !startDate.matches(self.startTime, to: .day) {
            updateDate(to: startDate)
        }
        
//        check if user is updating the tag
        if tagID != category?._id {
            if let retrievedTag = RecallCategory.getCategoryObject(from: tagID) {
                updateTag(with: retrievedTag)
            }
        }
        
//        check if the user is updating the goalRatings
        if let goalRatings {
            updateGoalRatings(with: goalRatings)
        }
        
//        update all other properties
        RealmManager.updateObject(self) { thawed in
            thawed.title = title
            thawed.notes = notes
            thawed.urlString = urlString
            
            let imageData = encodeImages(from: images)
            thawed.images = imageData
            
            if let location = location {
                thawed.locationTitle = location.title
                thawed.locationLongitude = location.location.longitude
                thawed.locationLatitude = location.location.latitude
            }
            
            RecallModel.shared.updateEvent(thawed, updateType: .update)
        }
    }
    
//    MARK: UpdateTime
    @MainActor
    func updateTime(startDate: Date? = nil, endDate: Date? = nil) {
        RealmManager.updateObject(self) { thawed in
            updateOldData(thawed)
            thawed.startTime = startDate ?? thawed.startTime
            thawed.endTime = endDate ?? thawed.endTime
            
            RecallModel.shared.updateEvent(thawed, updateType: .changeTime)
        }
    }
    
//    MARK: UpdateDate
    @MainActor
    func updateDate(to date: Date) {
        let newStart = self.startTime.dateBySetting(dateFrom: date)
        let newEnd = self.endTime.dateBySetting(dateFrom: date)
        
        RealmManager.updateObject(self) { thawed in
            updateOldData(thawed)
            thawed.startTime = newStart
            thawed.endTime = newEnd
            
            RecallModel.shared.updateEvent(thawed, updateType: .changeDate)
        }
    }
    
//    MARK: updateTag
    func updateTag(with tag: RecallCategory) {
        RealmManager.updateObject(self) { thawed in
            updateOldData(thawed)
            thawed.category = tag
            
            RecallModel.shared.updateEvent(thawed, updateType: .update)
        }
    }
    
//    MARK: UpdateGoalRatings
    @MainActor
    func updateGoalRatings(with ratings: Dictionary<String, String>) {
        let list = RecallCalendarEvent.translateGoalRatingDictionary(ratings)
        
        RealmManager.updateObject(self) { thawed in
            updateOldData(thawed)
            thawed.goalRatings = list
            
            RecallModel.shared.updateEvent(thawed, updateType: .changeGoals)
        }
    }
    
//    MARK: - get CalendarEvent
    static func getRecallCalendarEvent(from id: ObjectId) -> RecallCalendarEvent? {
        let results: Results<RecallCalendarEvent> = RealmManager.retrieveObject { query in query._id == id }
        guard let first = results.first else { print("no event exists with given id: \(id.stringValue)"); return nil }
        return first
    }
    
    
//    MARK:  GetLocationResult
//    checks if the event has any location data, and if it does, parses it into a locationResult and returns it
    func getLocationResult() -> LocationResult? {
        if self.locationTitle.isEmpty { return nil }
        
        return .init(location: .init(latitude: self.locationLatitude,
                              longitude: self.locationLongitude)
              , title: self.locationTitle)
    }
    
//    MARK: encodeImages
//    take a list of UIImages and return a RealmSwift list of Data
//    used in the initialization / update process
    private func encodeImages(from images: [UIImage]) -> RealmSwift.List<Data> {
        let list = RealmSwift.List<Data>()
        
        for image in images {
            let data = PhotoManager.encodeImage(image, compressionQuality: 0.45, in: 600)
            print("uploaded image. size: \(data.count)")
            list.append(data)
        }
        
        return list
    }
    
//    MARK: translateGoalRating
//    converts the list of Goal nodes into a swift dictionary
//    this is used in initialization and updating
    @MainActor
    func getRatingsDictionary() -> Dictionary<String,String> {
        RecallCalendarEvent.translateGoalRatingList(self.goalRatings)
    }

    static func translateGoalRatingDictionary(_ dictionary: Dictionary<String, String>) -> RealmSwift.List<GoalNode> {
        let list: RealmSwift.List<GoalNode> = List()
        list.append(objectsIn: dictionary.map { (key: String, data: String) in
            GoalNode(ownerID: RecallModel.ownerID, key: key, data: data)
        })
        return list
    }
    
//    convers a swift dictionary into a RealmSwift dictionary of goalNodes
    static func translateGoalRatingList( _ list: RealmSwift.List<GoalNode> ) -> Dictionary<String, String> {
        var dic = Dictionary<String, String>()
        for node in list { dic[node.key] = node.data }
        return dic
    }
    
//    MARK: ToggleFavorite
    @MainActor
    func toggleFavorite() {
        RealmManager.updateObject(self) { thawed in
            thawed.isFavorite = !self.isFavorite 
        }
        
        RecallModel.dataStore.checkMostRecentFavoriteEvent(against: self, isFavorite: !self.isFavorite)
    }
    
    
    
//    MARK: GetProperties
//    This is a list of all the goals this event's tag contributes to
    @MainActor
    func getGoals() -> [RecallGoal] {
        self.goalRatings.compactMap { node in
            if node.getNumericData() > 0 {
                if let goal = RecallGoal.getGoalFromKey(node.key) {
                    return goal
                }
            }
            return nil
        }
    }
    
    func getLengthInHours() -> Double { endTime.timeIntervalSince(startTime) / Constants.HourTime }
    
    func getDurationString() -> String {
        let hours = endTime.timeIntervalSince(startTime) / Constants.HourTime
        let roundedHours = floor(hours)
        let minutes = (hours - roundedHours) * 60
        
        let hourString = "\(Int(roundedHours)) hr "
        let minuteString = "\(Int(minutes))"
        
        return (Int(roundedHours) == 0 ? "" : hourString) + ( Int(minutes) == 0 ? "" : minuteString ) + (Int(roundedHours) == 0 ? " mins" : "")
    }
    
    func getColor() -> Color { category?.getColor() ?? Colors.defaultLightAccent }
    
    func getTagLabel() -> String { category?.label ?? "?"}
    
//    MARK: Delete
    @MainActor
    func delete(preserveTemplate: Bool = false) {
        
        if self.isFavorite { self.toggleFavorite() }
        
        updateOldData(self)
        
        RealmManager.deleteObject(self) { event in event._id == self._id }
        
        RecallModel.shared.updateEvent(self, updateType: .delete)

    }
    
//    MARK: GetGoalMultiplier
//    This checks to see if this event has a multiplier for a specifc goal (ie. coding should have 'productive')
    @MainActor
    func getGoalMultiplier(from goal: RecallGoal) -> Double {
        let key = goal.getEncryptionKey()
        let data = goalRatings.first { node in node.key == key }?.data ?? "0"
        return Double(data) ?? 0
    }
    
//    MARK: GetGoalProgress
    func getGoalPrgress(_ goal: RecallGoal) async -> Double {
        let multiplier = await getGoalMultiplier(from: goal)
        if RecallGoal.GoalType.getRawType(from: goal.type) == .hourly { return getLengthInHours() * multiplier }
        else if goal.targetTag?.label ?? "" == self.category?.label ?? "-" { return 1 }
        return 0
    }
    
//    MARK: GetGoalProgressThreadsInvariant
//    to avoid certain crashes the standard 'getGoalMultiplier' should mostly be run on the main thread
//    however, there are certain cases where its technically difficult to do so, 
//    but will not elicit a crash to run it on any thread
//    for those cases, run this function, it does the same work as 'getGoalProgress' but on any thread
    func getGoalProgressThreadInvariant( _ goal: RecallGoal ) -> Double {
        let key = goal.getEncryptionKey()
        let data = goalRatings.first { node in node.key == key }?.data ?? "0"
        let multiplier = Double(data) ?? 0
        
        if RecallGoal.GoalType.getRawType(from: goal.type) == .hourly { return getLengthInHours() * multiplier }
        else if goal.targetTag?.label ?? "" == self.category?.label ?? "-" { return 1 }
        return 0
    }
    
//    MARK: CreateWidgetEvent
//    Widgets take in a simplified version of calendar events, known as
//    RecallWigetCalendarEvent. This function translates an event into a widget event
    func createWidgetEvent() -> RecallWidgetCalendarEvent {
        .init(id: self._id.stringValue,
              title: self.title,
              notes: self.notes,
              tag: self.getTagLabel(),
              startTime: self.startTime,
              endTime: self.endTime,
              color: self.getColor()
        )
    }
}


//MARK: SampleEvent
let uiImage1 = UIImage(named: "sampleImage1")!
let uiImage2 = UIImage(named: "sampleImage2")!
let uiImage3 = UIImage(named: "sampleImage3")!

@MainActor
let sampleEvent = RecallCalendarEvent(ownerID: "",
                                    title: "test event",
                                    notes: "Its been a long long time. A moment to shine, shine, shine, shine, shinnnnnnnnnneeeeee. Ooooh ohh",
                                    urlString: "https://github.com/Brian-Masse/Recall",
                                    location: .init(location: .init(latitude: 42.5124232, longitude: -71.114742),
                                                      title: "25 Indian Tree Ln, Reading, MA  01867, United States"),
                                    images: [uiImage1, uiImage2, uiImage3],
                                    startTime: .now,
                                    endTime: .now + Constants.HourTime * 2,
                                          categoryID: ObjectId(),
                                    goalRatings: [:],
                                    previewEvent: true)

@MainActor
let sampleEventNoPhotos = RecallCalendarEvent(ownerID: "",
                                    title: "test event",
                                    notes: "Its been a long long time. A moment to shine, shine, shine, shine, shinnnnnnnnnneeeeee. Ooooh ohh",
                                    urlString: "https://github.com/Brian-Masse/Recall",
                                    location: .init(location: .init(latitude: 42.5124232, longitude: -71.114742),
                                                      title: "25 Indian Tree Ln, Reading, MA  01867, United States"),
                                    images: [],
                                    startTime: .now,
                                    endTime: .now + Constants.HourTime * 2,
                                          categoryID: ObjectId(),
                                    goalRatings: [:],
                                    previewEvent: true)
