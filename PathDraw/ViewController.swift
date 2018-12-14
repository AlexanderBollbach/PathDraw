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
import RxSwiftExt


class ViewController: UIViewController {
    
    private let controlsVC = ControlsVC()
    private let temporaryLineRender = LineRenderingView()
    private let pan = UIPanGestureRecognizer()
    private let tap = UITapGestureRecognizer.init()
    private let managedMapView = ManagedMapView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        _ = system.subscribe()
    }
}

extension ViewController {
    
    func configureViews() {
    
        addChild(controlsVC)
        
        let mapAndRendering = UIView()
        managedMapView.mapview.pinTo(superView: mapAndRendering)
        temporaryLineRender.pinTo(superView: mapAndRendering)
        
        let sv = UIStackView.init(arrangedSubviews: [mapAndRendering, controlsVC.view])
        
        sv.axis = .vertical
        
        sv.pinToLayoutMargin(superView: view)
        
        controlsVC.view.heightAnchor.constraint(equalTo: sv.heightAnchor, multiplier: 0.2).isActive = true
        
        controlsVC.didMove(toParent: self)
        
        [pan, tap].forEach(view.addGestureRecognizer)
    }
}


extension ViewController {
    
    struct State {
        
        enum EditingMode {
            case moving
            case drawing
        }
        var paths = [[MKMapPoint]]()
        var shouldSyncPaths: [[MKMapPoint]]? = nil
        
        var isDrawing = false
        
        var editingMode = EditingMode.moving
        
        init(paths: [[MKMapPoint]] = [], shouldSyncPaths: [[MKMapPoint]]? = nil) {
            self.paths = paths
            self.shouldSyncPaths = shouldSyncPaths
        }
    }
    
    enum Mutation {
        case startPath(MKMapPoint)
        case addPoint(MKMapPoint)
        case syncMapStart
        case syncMapStop
        case clearPath
        case setIsDrawing(Bool)
        case setMode(State.EditingMode)
    }
    
    var system: Observable<State> {
        return Observable.system(
            initialState: State(),
            reduce: { (state, mutation) -> State in
                
                switch mutation {
                    
                case .startPath(let point):
                    var state = state
                    var paths = state.paths
                    paths.append([point])
                    state.paths = paths
                    state.isDrawing = true
                    return state
                case .setMode(let val):
                    var state = state
                    state.editingMode = val
                    return state
                case .addPoint(let point):
                    var state = state
                    var paths = state.paths
                    paths[paths.count - 1].append(point)
                    state.paths = paths
                    return state
                case .syncMapStart:
                    var state = state
                    state.shouldSyncPaths = state.paths
                    state.isDrawing = false
                    return state
                case .syncMapStop:
                    var state = state
                    state.shouldSyncPaths = nil
                    return state
                case .clearPath:
                    var state = state
                    state.paths = []
                    state.shouldSyncPaths = []
                    return state
                case .setIsDrawing(let val):
                    var state = state
                    state.isDrawing = val
                    return state
                }
        },
            scheduler: MainScheduler.instance,
            scheduledFeedback: bind(self) { (me, state) -> Bindings<Mutation> in
                
                let muts: [Observable<Mutation>] = [
                    
                    me.pan.rx.event
                        .filter { $0.state == .began }
                        .map { mapPointFromGestureEvent(rec: $0, mapView: me.managedMapView.mapview, view: me.view) }
                        .map { Mutation.startPath($0) },
                    
                    me.pan.rx.event
                        .filter { return $0.state == .changed }
                        .map { mapPointFromGestureEvent(rec: $0, mapView: me.managedMapView.mapview, view: me.view) }
                        .map { Mutation.addPoint($0) },
                    
                    me.controlsVC.clearButton.rx.tap
                        .map { Mutation.clearPath },
                    
                    me.pan.rx.event
                        .filter { $0.state == .ended }
                        .map { _ in Mutation.syncMapStart },
                    
                    me.controlsVC.drawPathButton.rx.tap.asObservable()
                        .withLatestFrom(state)
                        .map {
                            let newMode = $0.editingMode == State.EditingMode.drawing ? State.EditingMode.moving : State.EditingMode.drawing
                            return Mutation.setMode(newMode)
                    }
                ]
                
                let subs = [
                    
                    state
                        .map { $0.paths }
                        .map { getDistance(paths: $0, mapView: me.managedMapView.mapview) }
                        .subscribe(onNext: { miles in
                            me.controlsVC.computedDataView.setMiles(miles)
                            me.controlsVC.computedDataView.setCalories(miles * 20)
                        }),
                    state.map { $0.editingMode }.subscribe(onNext: { mode in
                        me.temporaryLineRender.isVisible = mode == State.EditingMode.drawing
                        me.managedMapView.mapview.isScrollEnabled = mode != State.EditingMode.drawing
                        me.controlsVC.isDrawing = mode == State.EditingMode.drawing
                    }),
                    
                    state.map { $0.paths.last }.subscribe(onNext: { mapPoints in
                        let points = mapPoints ?? []
                        let converted = points
                            .map { $0.coordinate }
                            .map { me.managedMapView.mapview.convert($0, toPointTo: me.managedMapView.mapview) }
                        me.temporaryLineRender.render(points: converted)
                    }),
                    
                    state.map { $0.isDrawing }.subscribe(onNext: { isDrawing in
                      me.temporaryLineRender.isVisible = isDrawing
                    })
                ]
                
                return Bindings(subscriptions: subs, mutations: muts)
            },
            react(query: { return $0.shouldSyncPaths }, effects: { [weak self] foo -> Observable<Mutation> in
                self?.managedMapView.render(paths: foo)
                return .just(Mutation.syncMapStop)
            })
        )
    }
}

func mapPointFromGestureEvent(rec: UIPanGestureRecognizer, mapView: MKMapView, view: UIView) -> MKMapPoint {
    let point = rec.location(in: view)
    let p2 = view.convert(point, to: mapView)
    let p2p = mapView.convert(p2, toCoordinateFrom: mapView)
    return MKMapPoint(p2p)
}


extension CGPoint : Hashable {
    func distance(point: CGPoint) -> Float {
        let dx = Float(x - point.x)
        let dy = Float(y - point.y)
        return sqrt((dx * dx) + (dy * dy))
    }
    public var hashValue: Int {
        // iOS Swift Game Development Cookbook
        // https://books.google.se/books?id=QQY_CQAAQBAJ&pg=PA304&lpg=PA304&dq=swift+CGpoint+hashvalue&source=bl&ots=1hp2Fph274&sig=LvT36RXAmNcr8Ethwrmpt1ynMjY&hl=sv&sa=X&ved=0CCoQ6AEwAWoVChMIu9mc4IrnxgIVxXxyCh3CSwSU#v=onepage&q=swift%20CGpoint%20hashvalue&f=false
        return x.hashValue << 32 ^ y.hashValue
    }
}

