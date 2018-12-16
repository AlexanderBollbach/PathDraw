import UIKit
import MapKit
import UIKitHelp
import RxSwift
import RxCocoa
import RxSwiftExt
import ReSwift

struct NewPathEvent {
    let points: [MKMapPoint]
    let isBuilding: Bool
}

class ViewController: UIViewController, StoreSubscriber {
    
    let controlsVC = ControlsVC()
    let temporaryLineRender = LineRenderingView()
    let pan = UIPanGestureRecognizer()
    let tap = UITapGestureRecognizer.init()
    let managedMapView = ManagedMapView()
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        bind()
        
        store.subscribe(self)
    }
    
    func newState(state: UndoState) {
        
        let state = state.present
        
        let distance = getDistance(paths: state.paths, mapView: managedMapView.mapview)
        
        controlsVC.computedDataView.setMiles(distance)
        controlsVC.computedDataView.setCalories(distance * 20)
        
        managedMapView.mapview.isScrollEnabled = state.editingMode != .drawing
        controlsVC.isDrawing = state.editingMode == .drawing
        
        managedMapView.render(paths: state.paths)
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
    
    func bind() {
        
        enum PanEvent {
            case began(MKMapPoint)
            case changed(MKMapPoint)
            case ended
        }
        
        let began = pan.rx.event
            .filter { $0.state == .began }
            .map { [unowned self] in mapPointFromGestureEvent(rec: $0, mapView: self.managedMapView.mapview, view: self.view) }
            .map { PanEvent.began($0) }
        
        let changed = pan.rx.event
            .filter { return $0.state == .changed }
            .map { [unowned self] in  mapPointFromGestureEvent(rec: $0, mapView: self.managedMapView.mapview, view: self.view) }
            .map { PanEvent.changed($0) }
        
        let ended = pan.rx.event
            .filter { $0.state == .ended }
            .map { _ in PanEvent.ended }
        
        let pathUpdates = Observable<PanEvent>
            .merge(began, changed, ended)
            .scan(NewPathEvent(points: [], isBuilding: true)) { (pathEvent, panEvent) -> NewPathEvent in
                
            switch panEvent {
            case .began(let point):
                return NewPathEvent(points: [point], isBuilding: true)
            case .changed(let point):
                return NewPathEvent(points: pathEvent.points + [point], isBuilding: true)
            case .ended:
                return NewPathEvent(points: pathEvent.points, isBuilding: false)
            }
        }
        
        let buildingPath = pathUpdates.filterMap { $0.isBuilding ? .map($0.points) : .ignore }
        
        buildingPath.subscribe(onNext: { [unowned self] points in
            
            let converted = points
                .map { CLLocationCoordinate2D.init(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
                .map { self.managedMapView.mapview.convert($0, toPointTo: self.managedMapView.mapview) }
            
            self.temporaryLineRender.render(points: converted)
            
        }).disposed(by: bag)
        
        let newPath = pathUpdates.filterMap { $0.isBuilding ? .ignore : .map($0.points) }
        
        newPath.subscribe(onNext: { [unowned self] points in
            self.temporaryLineRender.render(points: [])
            store.dispatch(Actions.addPath(path: points))
        }).disposed(by: bag)
        
        controlsVC.events.filter { $0 == .clearPaths }
            .map { _ in Actions.clearPath() }
            .bind(to: dispatchObserver)
            .disposed(by: bag)
        
        controlsVC.events.filter { $0 == .toggleDrawMode }
            .map { _ in
                return Actions.setMode(
                    mode: store.state.present.editingMode == .drawing ? .moving : .drawing
                )
            }
            .bind(to: dispatchObserver)
            .disposed(by: bag)
        
        controlsVC.events.filter { $0 == ControlsEvent.undo }
            .map { _ in Actions.undo() }
            .bind(to: dispatchObserver)
            .disposed(by: bag)
        
        controlsVC.events.filter { $0 == ControlsEvent.redo }
            .map { _ in Actions.redo() }
            .bind(to: dispatchObserver)
            .disposed(by: bag)
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

