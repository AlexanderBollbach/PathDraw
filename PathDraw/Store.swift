import MapKit
import ReSwift

extension MKMapPoint: Equatable {
    public static func ==(lhs: MKMapPoint, rhs: MKMapPoint) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct AppState: Equatable {
    
    enum EditingMode: Equatable {
        case moving
        case drawing
    }
    
    var paths = [[MKMapPoint]]()
    var isDrawing = false
    var editingMode = EditingMode.moving
    
    init(paths: [[MKMapPoint]] = []) {
        self.paths = paths
    }
}

struct ClearPath: Action { }
struct SetMode: Action { let mode: AppState.EditingMode }
struct Undo: Action { }
struct Redo: Action { }
struct AddPath: Action { let path: [MKMapPoint] }

struct Actions {
    static func clearPath() -> Action { return ClearPath() }
    static func setMode(mode: AppState.EditingMode) -> Action { return SetMode(mode: mode) }
    static func undo() -> Action { return Undo() }
    static func redo() -> Action { return Redo() }
    static func addPath(path: [MKMapPoint]) -> Action { return AddPath(path: path) }
}

func rootReducer(action: Action, state: AppState?) -> AppState {
    
    let state = state ?? AppState()
    
    switch action {
        
    case is ClearPath:
        var state = state
        state.paths = []
        return state
        
    case let m as SetMode:
        var state = state
        state.editingMode = m.mode
        return state
        
    case let m as AddPath:
        var state = state
        state.paths.append(m.path)
        return state
        
    default:
        fatalError()
    }
}

struct UndoContainer<T>: StateType {
    var past: [T] = []
    var future: [T] = []
    var present: T
}

typealias UndoState = UndoContainer<AppState>

func undoReducer(reducer: @escaping (Action, AppState?) -> AppState) -> (Action, UndoState?) -> UndoState {
    return { action, state in
        
        let state = state ?? UndoContainer.init(past: [], future: [], present: reducer(action, nil))

        switch action {
        case is Undo:
            guard let previous = state.past.last else { return state } // nothing to do, undo stack empty
            return UndoContainer(
                past: Array(state.past.dropLast()),
                future: [state.present] + state.future,
                present: previous
            )
        case is Redo:
            guard let next = state.future.first else { return state } // nothing to do, redo stack empty
            return UndoContainer(
                past: state.past + [state.present],
                future: Array(state.future.dropFirst()),
                present: next
            )
        default:
            let newPresent = reducer(action, state.present)
            
            if newPresent == state.present {
                return state
            }
           
            return UndoContainer(
                past: state.past + [state.present],
                future: [],
                present: newPresent
            )
        }
    }
}
