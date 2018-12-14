//
//  Utilities.swift
//  PathDraw
//
//  Created by Alexander Bollbach on 11/24/18.
//  Copyright © 2018 Alexander Bollbach. All rights reserved.
//

import MapKit
import CoreGraphics

func getDistance(paths: [[MKMapPoint]], mapView: MKMapView) -> Double {
    return paths.reduce(0) { $0 + getDistance(points: $1, mapView: mapView) }
}

func getDistance(points: [MKMapPoint], mapView: MKMapView) -> Double {

    var dist: CLLocationDistance = 0
    
    for cs in zip(points, points.dropFirst()) {

        let a = cs.0.coordinate
        let b = cs.1.coordinate
        
        let c = a.distance(from: b)
        
        dist += c
    }
    
    return dist / 1609
}

extension CLLocationCoordinate2D {
    
    func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
        
        let destination = CLLocation(latitude: from.latitude, longitude: from.longitude)
        
        return CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: destination)
    }
}

extension MKMapView {
    
    func zoomToManhattan() {
        
        setRegion(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: 40.783,
                    longitude: -73.97
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: 0.1,
                    longitudeDelta: 0.1)
            ),
            animated: false
        )
    }
}
