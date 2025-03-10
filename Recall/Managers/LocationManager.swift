//
//  LocationManager.swift
//  Recall
//
//  Created by Brian Masse on 10/4/24.
//

import Foundation
import CoreLocation
import MapKit

extension CLLocation {
    func fetchCityAndCountry(completion: @escaping (_ city: String?, _ country:  String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first?.locality, $0?.first?.country, $1) }
    }
    
    func fetchCityAndCountry() async -> [CLPlacemark] {
        let res = try? await CLGeocoder().reverseGeocodeLocation(self)
        return res ?? []
    }
}



final class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    @Published var lastKnownLocation: CLLocationCoordinate2D?
    var manager = CLLocationManager()
    
    static let shared = LocationManager()
    
    func checkLocationAuthorization() {
        
        manager.delegate = self
        manager.startUpdatingLocation()
        
        switch manager.authorizationStatus {
        case .notDetermined://The user choose allow or denny your app to get the location yet
            manager.requestWhenInUseAuthorization()
            
        case .restricted://The user cannot change this app’s status, possibly due to active restrictions such as parental controls being in place.
            print("Location restricted")
            
        case .denied://The user dennied your app to get location or disabled the services location or the phone is in airplane mode
            print("Location denied")
            
        case .authorizedAlways://This authorization allows you to use all location services and receive location events whether or not your app is in use.
            print("Location authorizedAlways")
            
        case .authorizedWhenInUse://This authorization allows you to use all location services and receive location events only when your app is in use
            lastKnownLocation = manager.location?.coordinate
            
        @unknown default:
            print("Location service disabled")
        
        }
    }
    
    func getLocationInformation() async -> LocationResult? {
        self.checkLocationAuthorization()
        
        if let location = manager.location {
            var locationTitle = "Unnamed Location"
            
            if let placemark = await location.fetchCityAndCountry().first {
                locationTitle = (placemark.locality ?? "") + ", " + (placemark.country ?? "")
            }
            
            return .init(location: location.coordinate, title: locationTitle)
        }
        
        return nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {//Trigged every time authorization status changes
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations.first?.coordinate
    }
}
