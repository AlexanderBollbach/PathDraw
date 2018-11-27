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
import RxSwift
import RxCocoa
import RxFeedback

class ViewController: UIViewController {
    
    private let mapView = MKMapView()
    
    var drawnOverLay: MKOverlay?
    
    var points = [CGPoint]()
    
    private let appState: AppState
    
    let controlsVC = ControlsVC()
    
    var temporaryLineRender: LineRenderingView!
    
    init(appState: AppState) {
        self.appState = appState
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    let pan = UIPanGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
     
        // setup controls view
        
        addChild(controlsVC)
        
        view.addSubview(controlsVC.view)
        
        controlsVC.view.translatesAutoresizingMaskIntoConstraints = false
        controlsVC.view.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        controlsVC.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        controlsVC.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2).isActive = true
        controlsVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        controlsVC.didMove(toParent: self)

        // set map view
        view.addSubview(mapView)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mapView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        mapView.topAnchor.constraint(equalTo: controlsVC.view.bottomAnchor).isActive = true
        
        mapView.delegate = self
        
        // line renderer
        temporaryLineRender = LineRenderingView(appState: appState)
        
        view.addSubview(temporaryLineRender)
        
        temporaryLineRender.translatesAutoresizingMaskIntoConstraints = false
        
        temporaryLineRender.leftAnchor.constraint(equalTo: mapView.leftAnchor).isActive = true
        temporaryLineRender.rightAnchor.constraint(equalTo: mapView.rightAnchor).isActive = true
        temporaryLineRender.topAnchor.constraint(equalTo: mapView.topAnchor).isActive = true
        temporaryLineRender.bottomAnchor.constraint(equalTo: mapView.bottomAnchor).isActive = true
        
        view.addGestureRecognizer(pan)
        
        controlsVC.system.subscribe(onNext: { state in
            
            self.mapView.isScrollEnabled = !state.isDrawingPath
        })
        
        system.subscribe(onNext: { state in
            print(state)
        })
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
    
    var isDrawingPath = false {
        didSet {
            temporaryLineRender.isVisible = isDrawingPath
        }
    }
 
    struct State {
        var points = [CGPoint]()
    }
    
    enum Mutation {
        case startPath(CGPoint)
        case addPoint(CGPoint)
    }
    
    var system: Observable<State> {
        return Observable<Any>.system(
            initialState: State(),
            reduce: { (state, mutation) -> State in
                
                switch mutation {
                case .startPath(let point):
                    return State.init(points: [point])
                case .addPoint(let point):
                    return State(points: state.points + [point])
                }
        },
            scheduler: MainScheduler.instance,
            scheduledFeedback: bind(self) { (me, state) -> Bindings<Mutation> in
                
                let muts: [Observable<Mutation>] = [
                    me.pan.rx.event
                        .filter { return $0.state == UIGestureRecognizer.State.began }
                        .map { event in
                            let point = event.location(in: me.view)
                            return Mutation.startPath(point)
                    },
                    me.pan.rx.event
                        .filter { return $0.state == UIGestureRecognizer.State.changed }
                        .map { event in
                            let point = event.location(in: me.view)
                            return Mutation.addPoint(point)
                    },
                ]
                
                let subs = [
                    state.map { $0.points }
                        .map { String(describing: getDistance(points: $0, mapView: me.mapView)) }
                        .bind(to: me.controlsVC.displayLabel.rx.text)
                ]
                
                return Bindings(subscriptions: subs, mutations: muts)
            })
    }
}

extension ViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if overlay is MKPolyline {
            let r = MKPolylineRenderer(overlay: overlay)
            r.strokeColor = appState.lineRenderingColor
            r.lineWidth = appState.lineRenderingStrokeWidth
            return r
        }

        fatalError()
    }
}
