//
//  ControlsVC.swift
//  PathDraw
//
//  Created by Alexander Bollbach on 11/19/18.
//  Copyright © 2018 Alexander Bollbach. All rights reserved.
//

import UIKit
import RxFeedback
import RxSwift

class AppButton: UIButton {
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? UIColor.lightGray : UIColor.clear
        }
    }
}

class ControlsVC: UIViewController {
    
    struct State {
        var isDrawingPath: Bool
    }
    
    enum Mutation {
        case toggleDrawingPath
    }
    
    lazy var drawPathButton: UIButton = {
        let b = AppButton()
        b.setTitle("Draw Path", for: .normal)
        b.pinTo(superView: view)
        return b
    }()
    
    let displayLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .purple
        
        let sv = UIStackView(arrangedSubviews: [displayLabel, drawPathButton])
        
        sv.distribution = .fillEqually
        
        sv.pinTo(superView: view)
    }
}

extension ControlsVC {
    
    var system: Observable<ControlsVC.State> {
        return Observable.system(
            initialState: State(isDrawingPath: false),
            reduce: { (state, mutation) -> State in
                switch mutation {
                case .toggleDrawingPath:
                    return State(isDrawingPath: !state.isDrawingPath)
                }
        },
            scheduler: MainScheduler.instance,
            scheduledFeedback:
            bind(self) { me, state -> Bindings<Mutation> in
                return Bindings(
                    subscriptions: [
                        state.map { $0.isDrawingPath }.bind(to: me.drawPathButton.rx.isSelected)
                    ],
                    mutations: [
                        me.drawPathButton.rx.tap.map { Mutation.toggleDrawingPath }
                    ]
                )
            }
        )
    }
}
