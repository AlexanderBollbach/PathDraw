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

func whiteLabel() -> UILabel {
    
    let l = UILabel()
    l.textAlignment = .center
    l.textColor = .white
    return l
}

class ComputedDataView: UIView {
    
    let milesLabel = whiteLabel()
    let caloriesBurnedLabel = whiteLabel()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        let sv = UIStackView(arrangedSubviews: [milesLabel, caloriesBurnedLabel])
        sv.axis = .vertical
        sv.distribution = .fillEqually
        sv.pinTo(superView: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func setMiles(_ miles: Double) {
        
        let a = Double(round(100 * miles) / 100)
        let b = "\(String.init(describing: a)) miles"
        
        milesLabel.text = b
    }
    
    func setCalories(_ calories: Double) {
        
        caloriesBurnedLabel.text = "\(calories)"
    }
}

class ControlsVC: UIViewController {
    
    lazy var drawPathButton: UIButton = {
        let b = AppButton()
        b.setTitle("Draw Path", for: .normal)
        return b
    }()
    
    lazy var clearButton: UIButton = {
        let b = AppButton()
        b.setTitle("clear path", for: .normal)
        return b
    }()
    
    let computedDataView = ComputedDataView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .purple
        let sv = UIStackView(arrangedSubviews: [computedDataView, drawPathButton, clearButton])
        sv.distribution = .fillEqually
        sv.pinTo(superView: view)
    }
    
    var isDrawing = false {
        didSet {
            drawPathButton.isSelected = isDrawing
        }
    }
}

