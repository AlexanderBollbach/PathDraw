//
//  ManagedMapView.swift
//  PathDraw
//
//  Created by Alexander Bollbach on 12/5/18.
//  Copyright © 2018 Alexander Bollbach. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MapKit

class ManagedMapView: NSObject, MKMapViewDelegate {
    
    let mapview = MKMapView.init()
    
    override init() {
        super.init()
        mapview.delegate = self
        mapview.zoomToManhattan()
    }
    
    var cachedPaths = [[MKMapPoint]]()
    
    func render(paths: [[MKMapPoint]]) {
        
        if paths == cachedPaths {
            return
        }
        
        cachedPaths = paths
        
        mapview.removeOverlays(mapview.overlays)
        
        for path in paths {
            mapview.addOverlay(MKPolyline.init(points: path, count: path.count))
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            let r = MKPolylineRenderer(overlay: overlay)
            r.strokeColor = UIColor.red
            r.lineWidth = 5
            return r
        }
        
        fatalError()
    }
}

extension Reactive where Base: ManagedMapView {
    
    var render: Binder<[[MKMapPoint]]> {
        return Binder(base) { $0.render(paths: $1) }
    }
}
