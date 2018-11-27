//
//  Utilities.swift
//  PathDraw
//
//  Created by Alexander Bollbach on 11/24/18.
//  Copyright © 2018 Alexander Bollbach. All rights reserved.
//

import MapKit
import CoreGraphics


func getDistance(points: [CGPoint], mapView: MKMapView) -> Double {
    
    let coords = points
        .map { mapView.convert($0, toCoordinateFrom: mapView) }
    
    var dist: CLLocationDistance = 0
    
    for cs in zip(coords, coords.dropFirst()) {
        
        let a = CLLocation.init(latitude: cs.0.latitude, longitude: cs.0.longitude)
        let b = CLLocation.init(latitude: cs.1.latitude, longitude: cs.1.longitude)
        
        let c = a.distance(from: b)
        
        dist += c
    }
    
    let miles = dist / 1609
    
    return miles
}
