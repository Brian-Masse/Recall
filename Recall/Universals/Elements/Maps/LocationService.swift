//
//  LocationService.swift
//  Recall
//
//  Created by Brian Masse on 10/1/24.
//

import Foundation
import MapKit
import SwiftUI

//MARK: SearchResult
struct LocationResult: Identifiable, Hashable {
    let id = UUID()
    let location: CLLocationCoordinate2D
    let title: String

    static func == (lhs: LocationResult, rhs: LocationResult) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//MARK: SearchCompletions
//this is what is returned to the user as they get search completions when they type
struct SearchCompletions: Identifiable {
    let id = UUID()
    let title: String
    let subTitle: String
    var url: URL?
}

//MARK: Location Service
@Observable
class LocationService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter

    var completions = [SearchCompletions]()

    init(completer: MKLocalSearchCompleter) {
        self.completer = completer
        super.init()
        self.completer.delegate = self
    }

    func update(queryFragment: String) {
        completer.resultTypes = [.address, .pointOfInterest]
        completer.queryFragment = queryFragment
    }

    
//    called when the search field updates
//    fetches the autocomplete results and maps them into a list of items
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results.map { completion in
            
            let mapItem = completion.value(forKey: "_mapItem") as? MKMapItem
            
            return  .init(title: completion.title,
                          subTitle: completion.subtitle,
                          url: mapItem?.url)
        }
    }
    
//    called when the user taps on an autocompleted location, or when they hit return on the keyboard
    func search(with query: String, coordinate: CLLocationCoordinate2D? = nil) async throws -> [LocationResult] {
        let mapKitRequest = MKLocalSearch.Request()
        mapKitRequest.naturalLanguageQuery = query
        mapKitRequest.resultTypes = [.pointOfInterest, .address]
        
        if let coordinate {
            mapKitRequest.region = .init(.init(origin: .init(coordinate), size: .init(width: 1, height: 1)))
        }
        let search = MKLocalSearch(request: mapKitRequest)

        let response = try await search.start()

        return response.mapItems.compactMap { mapItem in
            guard let location = mapItem.placemark.location?.coordinate else { return nil }
            
            return .init(location: location, title: mapItem.placemark.title ?? "")
        }
    }
}
