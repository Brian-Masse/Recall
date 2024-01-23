//
//  RecallUpdate.swift
//  Recall
//
//  Created by Brian Masse on 11/14/23.
//

import Foundation
import RealmSwift

//MARK: RecallUpdate
class RecallUpdate: Object {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerId: String = UpdateManager.globalOwnerId
    
    @Persisted var version: String = "0.0.0"
    @Persisted var updateDescription: String = ""
    
    @Persisted var pages: RealmSwift.List<RecallUpdatePage> = List()
    
    
    convenience init( version: String, description: String, pages: [RecallUpdatePage] ) {
        self.init()
        self.version = version
        self.updateDescription = description
        
        self.pages.append(objectsIn: pages)
    }
    
}

//MARK: RecallUpdatePage
class RecallUpdatePage: Object {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerId: String = UpdateManager.globalOwnerId
    
    @Persisted var pageTitle: String = ""
    @Persisted var pageDescription: String = ""
    
    @Persisted var imageName: String = ""
    
    
    convenience init( _ title: String, pageDescription: String, imageName: String = "" ) {
        self.init()
        
        self.pageTitle = title
        self.pageDescription = pageDescription
        self.imageName = imageName
        
    }
}
