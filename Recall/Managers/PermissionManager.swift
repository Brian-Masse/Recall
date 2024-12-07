//
//  PermissionManager.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import RealmSwift

enum QuerySubKey: String, CaseIterable {
    case calendarComponent
    case category
    case goal
    case goalNode
    case index
    case dictionary
    case summary
    case dataStore
}


//MARK: QueryPermission
class QueryPermission<T: Object> {
    
    let name: String
    let query: ((Query<T>) -> Query<Bool>)
    
    var addedSubscription: Bool = false
    
    private var additionalQueries: [ QueryPermission<T> ] = []
    
    init( named name: String, query: @escaping (Query<T>) -> Query<Bool> ) {
        self.name = name
        self.query = query
    }
    
    func getSubscription() -> QuerySubscription<T> {
        self.addedSubscription = true
        return QuerySubscription(name: name, query: query)
    }
    
    func addQuery(_ name: String, _ query: @escaping ((Query<T>) -> Query<Bool>) ) async {
        let additionalQuery = QueryPermission(named: name, query: query)
        
//        let _ = await RecallModel.realmManager.addGenericSubcriptions(name: name, query: query)
        additionalQueries.append(additionalQuery)
    }
    
    func removeQuery(_ name: String) async {
        await RecallModel.realmManager.removeSubscription(name: name)
        if let index = additionalQueries.firstIndex(where: { wrappedQuery in
            wrappedQuery.name == name
        }) {
            additionalQueries.remove(at: index)
        }
    }
    
    func removeAllNonBaseQueries() async {
        for query in additionalQueries {
            await removeQuery( query.name )
        }
    }
}
