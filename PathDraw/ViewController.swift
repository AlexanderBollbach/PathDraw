//
//  ViewController.swift
//  PathDraw
//
//  Created by Alexander Bollbach on 11/18/18.
//  Copyright © 2018 Alexander Bollbach. All rights reserved.
//

import UIKit
import MapKit
import UIKitHelp

class ViewController: UIViewController {
    
    private let mapView = MKMapView()
    
    var drawnOverLay: MKOverlay?
    
    var points = [CGPoint]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.pinTo(superView: view)

        mapView.delegate = self

        let controlsVC = ControlsVC()

        addChild(controlsVC)
        
        view.addSubview(controlsVC.view)
        
        controlsVC.view.translatesAutoresizingMaskIntoConstraints = false
        controlsVC.view.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        controlsVC.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        controlsVC.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2).isActive = true
        controlsVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        controlsVC.didMove(toParent: self)
        
    }
    
    @objc private func pressed(r: UILongPressGestureRecognizer) {

        switch r.state {
        case .began:
            let isEnabled = mapView.isScrollEnabled
            mapView.isScrollEnabled = !isEnabled
        default:
            break
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
        zoomToManhattan()
        
    }
    
    func zoomToManhattan() {
        
        mapView.setRegion(
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
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        print(self.view.constraints.count)

    }
    
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        if let overlay = self.drawnOverLay {
            mapView.removeOverlay(overlay)
        }

        points.removeAll()

        if let loc = touches.first?.location(in: self.view) {
            points.append(loc)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        if let loc = touches.first?.location(in: self.view) {
            points.append(loc)
        }
    }


    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        let coords = coordinates(from: points, in: mapView)
        let line = MKPolyline.init(points: coords, count: coords.count)

        self.drawnOverLay = line

        mapView.addOverlay(line)

        distance()
    }

    func distance() {

        let coords = points.map { mapView.convert($0, toCoordinateFrom: mapView) }

        var dist: CLLocationDistance = 0

        for cs in zip(coords, coords.dropFirst()) {

            let a = CLLocation.init(latitude: cs.0.latitude, longitude: cs.0.longitude)
            let b = CLLocation.init(latitude: cs.1.latitude, longitude: cs.1.longitude)

            let c = a.distance(from: b)

            dist += c
        }

        print(dist / 1609)
    }
}

extension ViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if overlay is MKPolyline {
            let r = MKPolylineRenderer(overlay: overlay)
            r.strokeColor = .red
            r.lineWidth = 5
            return r
        }

        fatalError()
    }
}


extension ViewController {

    func coordinates(from cgpoints: [CGPoint], in mapview: MKMapView) -> [MKMapPoint] {
        return cgpoints
            .map { mapview.convert($0, toCoordinateFrom: mapview) }
            .map(MKMapPoint.init)
    }
}

