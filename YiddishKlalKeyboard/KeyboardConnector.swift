//
//  KeyboardConnector.swift
//  Yiddish Klal - A Standard Yiddish keyboard layout for iOS
//
//  Adapted from tasty-imitation-keyboard by Alexei Baboulevitch
//  Copyright (c) 2014 Alexei Baboulevitch (archagon)
//  Original: https://github.com/archagon/tasty-imitation-keyboard
//
//  Modifications Copyright © 2026 Isaac L. Bleaman
//
//  See LICENSE.txt for full license terms
//

import UIKit

class KeyboardConnector: KeyboardKeyBackground {
    
    var start: UIView
    var end: UIView
    var startDir: Direction
    var endDir: Direction
    
    weak var startConnectable: Connectable?
    weak var endConnectable: Connectable?
    var convertedStartPoints: (CGPoint, CGPoint)!
    var convertedEndPoints: (CGPoint, CGPoint)!
    
    var offset: CGPoint
    
    init(cornerRadius: CGFloat, underOffset: CGFloat, start s: UIView, end e: UIView, startConnectable sC: Connectable, endConnectable eC: Connectable, startDirection: Direction, endDirection: Direction) {
        start = s
        end = e
        startDir = startDirection
        endDir = endDirection
        startConnectable = sC
        endConnectable = eC
        
        offset = CGPoint.zero
        
        super.init(cornerRadius: cornerRadius, underOffset: underOffset)
        
        // Disable user interaction so touches pass through
        self.isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        self.resizeFrame()
        super.layoutSubviews()
    }
    
    func generateConvertedPoints() {
        if self.startConnectable == nil || self.endConnectable == nil {
            return
        }
        
        if let superview = self.superview {
            let startPoints = self.startConnectable!.attachmentPoints(self.startDir)
            let endPoints = self.endConnectable!.attachmentPoints(self.endDir)
            
            self.convertedStartPoints = (
                superview.convert(startPoints.0, from: self.start),
                superview.convert(startPoints.1, from: self.start))
            self.convertedEndPoints = (
                superview.convert(endPoints.0, from: self.end),
                superview.convert(endPoints.1, from: self.end))
        }
    }
    
    func resizeFrame() {
        generateConvertedPoints()
        
        let buffer: CGFloat = 32
        self.offset = CGPoint(x: buffer/2, y: buffer/2)
        
        let minX = min(convertedStartPoints.0.x, convertedStartPoints.1.x, convertedEndPoints.0.x, convertedEndPoints.1.x)
        let minY = min(convertedStartPoints.0.y, convertedStartPoints.1.y, convertedEndPoints.0.y, convertedEndPoints.1.y)
        let maxX = max(convertedStartPoints.0.x, convertedStartPoints.1.x, convertedEndPoints.0.x, convertedEndPoints.1.x)
        let maxY = max(convertedStartPoints.0.y, convertedStartPoints.1.y, convertedEndPoints.0.y, convertedEndPoints.1.y)
        let width = maxX - minX
        let height = maxY - minY
        
        self.frame = CGRect(x: minX - buffer/2, y: minY - buffer/2, width: width + buffer, height: height + buffer)
    }
    
    override func generatePointsForDrawing(_ bounds: CGRect) {
        guard let startConnectable = startConnectable, let endConnectable = endConnectable else {
            return
        }
        
        let startPoints = startConnectable.attachmentPoints(self.startDir)
        let endPoints = endConnectable.attachmentPoints(self.endDir)
        
        var convertedStartPoints = (
            self.convert(startPoints.0, from: self.start),
            self.convert(startPoints.1, from: self.start))
        let convertedEndPoints = (
            self.convert(endPoints.0, from: self.end),
            self.convert(endPoints.1, from: self.end))
        
        if self.startDir == self.endDir {
            let tempPoint = convertedStartPoints.0
            convertedStartPoints.0 = convertedStartPoints.1
            convertedStartPoints.1 = tempPoint
        }
        
        let isVertical = (self.startDir == Direction.up || self.startDir == Direction.down) && (self.endDir == Direction.up || self.endDir == Direction.down)
        
        var midpoint: CGFloat
        if  isVertical {
            midpoint = convertedStartPoints.0.y + (convertedEndPoints.1.y - convertedStartPoints.0.y) / 2
        }
        else {
            midpoint = convertedStartPoints.0.x + (convertedEndPoints.1.x - convertedStartPoints.0.x) / 2
        }
        
        let bezierPath = UIBezierPath()
        var edgePaths = [UIBezierPath]()
        
        bezierPath.move(to: convertedStartPoints.0)
        
        bezierPath.addCurve(
            to: convertedEndPoints.1,
            controlPoint1: (isVertical ?
                            CGPoint(x: convertedStartPoints.0.x, y: midpoint) :
                                CGPoint(x: midpoint, y: convertedStartPoints.0.y)),
            controlPoint2: (isVertical ?
                            CGPoint(x: convertedEndPoints.1.x, y: midpoint) :
                                CGPoint(x: midpoint, y: convertedEndPoints.1.y)))
        
        var currentEdgePath = UIBezierPath()
        currentEdgePath.move(to: convertedStartPoints.0)
        currentEdgePath.addCurve(
            to: convertedEndPoints.1,
            controlPoint1: (isVertical ?
                            CGPoint(x: convertedStartPoints.0.x, y: midpoint) :
                                CGPoint(x: midpoint, y: convertedStartPoints.0.y)),
            controlPoint2: (isVertical ?
                            CGPoint(x: convertedEndPoints.1.x, y: midpoint) :
                                CGPoint(x: midpoint, y: convertedEndPoints.1.y)))
        currentEdgePath.apply(CGAffineTransform(translationX: 0, y: -self.underOffset))
        edgePaths.append(currentEdgePath)
        
        bezierPath.addLine(to: convertedEndPoints.0)
        
        bezierPath.addCurve(
            to: convertedStartPoints.1,
            controlPoint1: (isVertical ?
                            CGPoint(x: convertedEndPoints.0.x, y: midpoint) :
                                CGPoint(x: midpoint, y: convertedEndPoints.0.y)),
            controlPoint2: (isVertical ?
                            CGPoint(x: convertedStartPoints.1.x, y: midpoint) :
                                CGPoint(x: midpoint, y: convertedStartPoints.1.y)))
        bezierPath.addLine(to: convertedStartPoints.0)
        
        currentEdgePath = UIBezierPath()
        currentEdgePath.move(to: convertedEndPoints.0)
        currentEdgePath.addCurve(
            to: convertedStartPoints.1,
            controlPoint1: (isVertical ?
                            CGPoint(x: convertedEndPoints.0.x, y: midpoint) :
                                CGPoint(x: midpoint, y: convertedEndPoints.0.y)),
            controlPoint2: (isVertical ?
                            CGPoint(x: convertedStartPoints.1.x, y: midpoint) :
                                CGPoint(x: midpoint, y: convertedStartPoints.1.y)))
        currentEdgePath.apply(CGAffineTransform(translationX: 0, y: -self.underOffset))
        edgePaths.append(currentEdgePath)
        
        bezierPath.addLine(to: convertedStartPoints.0)
        
        bezierPath.close()
        bezierPath.apply(CGAffineTransform(translationX: 0, y: -self.underOffset))
        
        self.fillPath = bezierPath
        self.edgePaths = edgePaths
    }
}
