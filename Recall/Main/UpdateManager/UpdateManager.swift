//
//  UpdateManager.swift
//  Recall
//
//  Created by Brian Masse on 11/11/23.
//

import Foundation
import RealmSwift
import SwiftUI
import Realm

class UpdateManager: ObservableObject {
    
    enum UpdateSubscriptionKeys: String {
        case RecallUpdate
        case RecallUpdatePage
        case RecallRecentUpdate
    }
    
//    MARK: Vars
    static let updateAppID = "recalupdateapp-rhkhr"
    static let globalOwnerId = "global-id"
    static let localVersionKey = "localVeresionKey"
    static let deploymentVersion = "1.2.1"
    
    var localVersion: String = "0.0.0"
    
    let defaults = UserDefaults.standard
    
    let app = RealmSwift.App(id: UpdateManager.updateAppID )
    var user: RealmSwift.User? = nil
    private var realm: Realm? = nil
    
    @Published var outdatedClient: Bool = false
    @Published var outdatedUpdates: [RecallUpdate] = []
    
    func getRealm() -> Realm {
        self.realm!
    }
    
//    Once the RealmManager has signed in a user and opened a realm it will call this function
//    this makes sure that the logic to add subscriptions does not fail
//    MARK: Initialize
    @MainActor
    func initialize() async {
//        check if there is already a user signed into the updateApp
//        if there is not, sign them in anonymously
        await self.checkLogin()
        
        await self.openRealm()
        
        self.saveVersion("1.0.0")
        

//        if this function detects that the client is freshly updated, it will capture all the update logs
//        and store them in the 'outdatedUpdates' var
        self.localVersion = retrieveLocalVersion()
    
    }
    
//    MARK: Version Management
//    this function pulls what version the client SHOULD be on
//    in reality they might not actually be on this version, the actual version theyre on is hardcoded in deployment version
    @MainActor
    private func retrieveRemoteVersion() -> RecallRecentUpdate {
        if let recentUpdateObject: RecallRecentUpdate = RealmManager.retrieveObject(realm: self.realm).first {
            return recentUpdateObject
        }
        let version = "1.0.0"
        let recentUpdateObject = RecallRecentUpdate(version: version)
        RealmManager.addObject(  recentUpdateObject, realm: self.realm )
        return recentUpdateObject
    }
    
    @MainActor
    private func retrieveLocalVersion() -> String {
        
        let remoteVersion = retrieveRemoteVersion()
        
        if let localVersion = defaults.string(forKey: UpdateManager.localVersionKey) {
            if localVersion != UpdateManager.deploymentVersion {
                self.outdatedClient = true
                
                let outDatedVersions = remoteVersion.getOutdatedVersions(from: localVersion, to: UpdateManager.deploymentVersion)
                
                let updates: [RecallUpdate] = RealmManager.retrieveObjects(realm: self.realm) { query in
                    outDatedVersions.contains { str in str == query.version }
                }
                
                self.outdatedUpdates = updates
                
                return localVersion
            }
            
            
        } else { saveVersion(UpdateManager.deploymentVersion) }
        return UpdateManager.deploymentVersion
    }
    
//    This should be the next sequential version, this function does not order version history
//    that would require converting the "x.x.x." string into a number and comparing which will be challenging
//    this will only be run once for every update, by an admin.
    @MainActor
    private func addVersion( _ version: String, description: String, pages: [RecallUpdatePage] ) {
        
        let remoteVersion = retrieveRemoteVersion()
        
        if let _: RecallUpdate  = RealmManager.retrieveObject(realm: self.realm, where: { query in
            query.version == version
        }).first {
            print("attemping to add a version that already exists in history: \( version )")
            remoteVersion.addVersionToHistory(version)
        } else {
            
            let updateObject = RecallUpdate(version: version, description: description, pages: pages)
            RealmManager.addObject(updateObject, realm: self.realm)
            remoteVersion.addVersionToHistory(version)
            
        }
    }

    
//    MARK: Convenience Function
    
    private func saveVersion( _ version: String ) {
        defaults.set(version, forKey: UpdateManager.localVersionKey)
    }
    
    func dismissUpdateView() {
        self.saveVersion( UpdateManager.deploymentVersion )
        withAnimation { self.outdatedClient = false }
    }
    
    
    
//    MARK: UserAuthentication
    @MainActor
    private func checkLogin() async {
        if let user = self.app.currentUser {
            self.user = user
        } else {
            await self.login()
        }
    }
    
    @MainActor
    private func login() async {
        let credentials = RealmSwift.Credentials.anonymous
        
        do { self.user = try await self.app.login(credentials: credentials) }
        catch { print("error logging in: \(error.localizedDescription)") }
    }
    
//    MARK: OpenRealm
    
    private func createConfiguration(user: RealmSwift.User) -> Realm.Configuration {
        return user.flexibleSyncConfiguration(initialSubscriptions: { subs in
            
            let _: RecallUpdate? = self.addGenericSubscription(UpdateSubscriptionKeys.RecallUpdate.rawValue, subscriptions: subs)
            let _: RecallUpdatePage? = self.addGenericSubscription(UpdateSubscriptionKeys.RecallUpdatePage.rawValue, subscriptions: subs)
            let _: RecallRecentUpdate? = self.addGenericSubscription(UpdateSubscriptionKeys.RecallRecentUpdate.rawValue, subscriptions: subs)
            }
        )
    }
    
    private func openRealm() async {

        if let user = self.user {
            let configuration = createConfiguration(user: user)
            do {
                self.realm = try await Realm(configuration: configuration)
            } catch {
                print( "error opening updateRealm: \(error.localizedDescription)" )
            }
        }
    }
    
    private func addGenericSubscription<T: RealmSwiftObject>(_ name: String, subscriptions: SyncSubscriptionSet) -> T? {
        let subsExist = subscriptions.first(named: UpdateSubscriptionKeys.RecallUpdate.rawValue)
            
        if (subsExist != nil) {
            return nil
        } else {
            subscriptions.append(QuerySubscription<T>(name: name))
        }
        
        return nil
    }
}


//MARK: RecallRecentUpdate
class RecallRecentUpdate: Object {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerId: String = UpdateManager.globalOwnerId
    
    @Persisted var version: String = ""
    @Persisted var versionHistory: RealmSwift.List<String> = List()
    
    convenience init( version: String ) {
        self.init()
        self.version = version
        self.versionHistory.append( version )
    }
    
//    MARK: Convenienve Functions
    
    @MainActor
    func addVersionToHistory(_ version: String) {
        
        if let _ = self.versionHistory.firstIndex(of: version) { return }
        else {
            RealmManager.updateObject(realm: RecallModel.updateManager.getRealm(), self) { thawed in
                self.versionHistory.append(version)
            }
        }
    }
    
    @MainActor
//    this collects all the versions in between your old version and the current version
    func getOutdatedVersions(from oldVersion: String, to currentVersion: String) -> [String] {
        var versions: [String] = []
        
        if let index = versionHistory.firstIndex(of: oldVersion) {
            if index != versionHistory.count - 1 {
                for i in (index + 1..<versionHistory.count) {
                    versions.append( versionHistory[i] )
                    
                    if versionHistory[ i ] == currentVersion {
                        return versions
                    }
                }
            }
        }
        return versions
    }
}

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
