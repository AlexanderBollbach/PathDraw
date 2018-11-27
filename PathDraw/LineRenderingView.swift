//
//  LineRenderingView.swift
//  PathDraw
//
//  Created by Alexander Bollbach on 11/24/18.
//  Copyright © 2018 Alexander Bollbach. All rights reserved.
//

import UIKit

class LineRenderingView: UIView {
    
    private let appState: AppState
    
    private var points = [CGPoint]()
    
    init(appState: AppState) {
        self.appState = appState
        super.init(frame: .zero)
        
        backgroundColor = .clear
        
        isOpaque = false
        
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func render(points: [CGPoint]) {
        self.points = points
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        
        
        guard
            let firstPoint = self.points.first,
            let ctx = UIGraphicsGetCurrentContext()
            else {
                return
        }
        
//        ctx.setStrokeColor(appState.lineRenderingColor.cgColor)
        ctx.setStrokeColor(UIColor.blue.cgColor)
        ctx.setLineWidth(appState.lineRenderingStrokeWidth)
        
        ctx.move(to: firstPoint)
        
        for point in self.points.dropFirst() {
            ctx.addLine(to: point)
        }
        
        ctx.strokePath()
    }
}
