//
//  RealmManager.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import RealmSwift
import Realm



//this handles logging in, and opening the right realm with the right credentials
class RealmManager: ObservableObject {
    
    static let appID = "application-0-incki"
    
//    This realm will be generated once the profile has authenticated themselves (handled in LoginModel)
//    and the AsyncOpen call in LoginView has completed
    var realm: Realm!
    var app = RealmSwift.App(id: RealmManager.appID)
    var configuration: Realm.Configuration!
    
    var index: RecallIndex!
    
//    This is the realm profile that signed into the app
    var user: User?
    
    @Published var signedIn: Bool = false
    @Published var realmLoaded: Bool = false
    @Published var hasProfile: Bool = false
    
//    These can add, remove, and return compounded queries. During the app lifecycle, they'll need to change based on the current view
    @MainActor lazy var calendarEventQuery: (QueryPermission<RecallCalendarEvent>) = QueryPermission {query in query.ownerID == RecallModel.ownerID }
    @MainActor lazy var categoryQuery: (QueryPermission<RecallCategory>) = QueryPermission { query in query.ownerID == RecallModel.ownerID }
    @MainActor lazy var goalsQuery: (QueryPermission<RecallGoal>) = QueryPermission { query in query.ownerID == RecallModel.ownerID }
    @MainActor lazy var goalsNodeQuery: (QueryPermission<GoalNode>) = QueryPermission { query in query.ownerID == RecallModel.ownerID }
    @MainActor lazy var indexQuery: (QueryPermission<RecallIndex>) = QueryPermission { query in query.ownerID == RecallModel.ownerID }
    
    @MainActor
    init() {
        self.checkLogin()
    }
    
//    MARK: Authentication Functions
//    If there is a user already signed in,skip the user authentication system
    @MainActor
    func checkLogin() {
        if let user = app.currentUser {
            self.user = user
            self.postAuthenticationInit()
        }
    }
    
//    Called by the LoginModel once credentials are provided
    func authUser(credentials: Credentials) async -> Error? {
//        this simply logs the profile in and returns any status errors
//        Once the user is signed in, the LoginView loads the realm using the config generated in self.post-authentication()
        do {
            self.user = try await app.login(credentials: credentials)
            await self.postAuthenticationInit()
            return nil
        } catch { print("error logging in: \(error.localizedDescription)"); return error }
    }
    
    @MainActor
    private func postAuthenticationInit() {
        self.setConfiguration()
        self.signedIn = true
    }
    
    private func setConfiguration() {
        self.configuration = user!.flexibleSyncConfiguration(clientResetMode: .discardUnsyncedChanges())
        self.configuration.schemaVersion = 1
        
        Realm.Configuration.defaultConfiguration = self.configuration
    }
    
    static func stripEmail(_ email: String) -> String {
        email
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
//    only needs to run for email + password signup
    func registerUser(_ email: String, _ password: String) async -> Error? {
        
        let client = app.emailPasswordAuth
        do {
            try await client.registerUser(email: email, password: password)
            return nil
        } catch {
            if error.localizedDescription == "name already in use" { return nil }
            print("failed to register user: \(error.localizedDescription)")
            return error
        }
    }
    
    func logoutUser() {
        if let user = self.user {
            user.logOut { error in
                if let error = error { print("error logging out: \(error.localizedDescription)") }
                
                DispatchQueue.main.sync {
                    self.signedIn = false
                    self.hasProfile = false
                    self.realmLoaded = false
                }
            }
        }
    }
    
//    MARK: Profile Functions
    
    private func addProfileSubscription() async {
//        let _:EcheveriaProfile? = await self.addGenericSubcriptions(name: QuerySubKey.account.rawValue, query: profileQuery.baseQuery)
    }
    
//    if the user has a profile, then skip past the create profile UI
//    if not the profile objcet on EcheveriaModel will remain nil and the UI will show
    func checkProfile() async {
//     the only place the subscription is added is when they create a profile
//        if !self.checkSubscription(name: QuerySubKey.account.rawValue) { await self.addProfileSubscription() }
        
//        DispatchQueue.main.sync {
//            let profile = realm.objects(EcheveriaProfile.self).where { queryObject in
//                queryObject.ownerID == self.user!.id
//            }.first
//            if profile != nil { registerProfileLocally(profile!) }
//        }
    }
    
//    If they dont, this function is called to create one. It is sent in from the CreateProfileView
//    func addProfile( profile: EcheveriaProfile ) async {
////        Add Subscription to donwload your profile
//        await addProfileSubscription()
//
////        DispatchQueue.main.sync {
////            profile.ownerID = user!.id
////            EcheveriaModel.addObject(profile)
////            registerProfileLocally(profile)
////        }
//    }
    
//    whether you're loading the profile from the databae or creating at startup, it should go throught this function to
//    let the model know that the profile now has a profile and send that profile object to the model
//    TODO: Im not sure if the model should store a copy of the profile. It might be better to pull directyl from the DB, but for now this works
//    private func registerProfileLocally( _ profile: EcheveriaProfile ) {
//        hasProfile = true
//        EcheveriaModel.shared.setProfile(with: profile)
//    }

//    MARK: Realm-Loaded Functions
//    Called once the realm is loaded in OpenSyncedRealmView
    @MainActor
    func authRealm(realm: Realm) async {
        self.realm = realm
        await self.addSubcriptions()
        
        self.realmLoaded = true
        
        print("User Realm User file location: \(realm.configuration.fileURL!.path)")
        
//        This should be done during the create profile phase of the authentication process, but because that doesnt really exist right now, its just going to run automatically here
        let results: Results<RecallIndex> = RealmManager.retrieveObject()
        if let index = results.first {
            self.index = index
        } else {
            self.index = RecallIndex(ownerID: user!.id)
            RealmManager.addObject(self.index)
        }
    }
    
    private func addSubcriptions() async {
//            This is a clunky way of doing this
//            Effectivley, the order is login -> authenticate user (setup dud realm configuration) -> create synced realm (with responsive UI)
//             ->add the subscriptions (which downloads the data from the cloud) -> enter into the app with proper config and realm
//            Instead, when creating the configuration, use initalSubscriptions to provide the subs before creating the relam
//            This wasn't working before, but possibly if there is an instance of Realm in existence it might work?

        await self.removeAllNonBaseSubscriptions()
        
        let _:RecallCalendarEvent?  = await self.addGenericSubcriptions(name: QuerySubKey.calendarComponent.rawValue, query: calendarEventQuery.baseQuery )
        let _:RecallCategory?       = await self.addGenericSubcriptions(name: QuerySubKey.category.rawValue, query: categoryQuery.baseQuery )
        let _:RecallGoal?           = await self.addGenericSubcriptions(name: QuerySubKey.goal.rawValue, query: goalsQuery.baseQuery )
        let _:GoalNode?             = await self.addGenericSubcriptions(name: QuerySubKey.goalNode.rawValue, query: goalsNodeQuery.baseQuery )
        let _:RecallIndex?          = await self.addGenericSubcriptions(name: QuerySubKey.index.rawValue, query: indexQuery.baseQuery )
        
    }
    
//    MARK: Helper Functions
    func addGenericSubcriptions<T>(name: String, query: @escaping ((Query<T>) -> Query<Bool>) ) async -> T? where T:RealmSwiftObject  {
            
        let subscriptions = self.realm.subscriptions
        
        do {
            try await subscriptions.update {
                
                let querySub = QuerySubscription(name: name, query: query)

                if checkSubscription(name: name) {
                    let foundSubscriptions = subscriptions.first(named: name)!
                    foundSubscriptions.updateQuery(toType: T.self, where: query)
                }
                else { subscriptions.append(querySub)}
            }
        } catch { print("error adding subcription: \(error)") }
        return nil
    }
    
    func removeSubscription(name: String) async {
            
        let subscriptions = self.realm.subscriptions
        let foundSubscriptions = subscriptions.first(named: name)
        if foundSubscriptions == nil {return}
        
        do {
            try await subscriptions.update{
                subscriptions.remove(named: name)
            }
        } catch { print("error adding subcription: \(error)") }
    }
    
    private func checkSubscription(name: String) -> Bool {
        let subscriptions = self.realm.subscriptions
        let foundSubscriptions = subscriptions.first(named: name)
        return foundSubscriptions != nil
    }
    
    func removeAllNonBaseSubscriptions() async {
        
        if let realm = self.realm {
            if realm.subscriptions.count > 0 {
                for subscription in realm.subscriptions {
                    if !QuerySubKey.allCases.contains(where: { key in
                        key.rawValue == subscription.name
                    }) {
                        await self.removeSubscription(name: subscription.name!)
                        
                    }
                }
            }
        }
    }
    
//    MARK: Realm Functions
    
    static func writeToRealm(_ block: () -> Void ) {
        do {
            if RecallModel.realmManager.realm.isInWriteTransaction { block() }
            else { try RecallModel.realmManager.realm.write(block) }
            
        } catch { print("ERROR WRITING TO REALM:" + error.localizedDescription) }
    }
    
    static func updateObject<T: Object>(_ object: T, _ block: (T) -> Void, needsThawing: Bool = true) {
        RealmManager.writeToRealm {
            guard let thawed = object.thaw() else {
                print("failed to thaw object: \(object)")
                return
            }
            block(thawed)
        }
    }
    
    static func addObject<T:Object>( _ object: T ) {
        self.writeToRealm { RecallModel.realmManager.realm.add(object) }
    }
    
    static func retrieveObject<T:Object>( where query: ( (Query<T>) -> Query<Bool> )? = nil ) -> Results<T> {
        if query == nil { return RecallModel.realmManager.realm.objects(T.self) }
        else { return RecallModel.realmManager.realm.objects(T.self).where(query!) }
    }
    
    @MainActor
    static func retrieveObjects<T: Object>(where query: ( (T) -> Bool )? = nil ) -> [T] {
        if query == nil { return Array(RecallModel.realmManager.realm.objects(T.self)) }
        else { return Array(RecallModel.realmManager.realm.objects(T.self).filter(query!)  ) }
        
        
    }
    
    static func deleteObject<T: RealmSwiftObject>( _ object: T, where query: @escaping (T) -> Bool ) where T: Identifiable {
        
        if let obj = RecallModel.realmManager.realm.objects(T.self).filter( query ).first {
            self.writeToRealm {
                RecallModel.realmManager.realm.delete(obj)
            }
        }
    }
    
}

