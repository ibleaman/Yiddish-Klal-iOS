//
//  KeyboardKey.swift
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

protocol KeyboardKeyProtocol: AnyObject {
    func popupFrame(for key: KeyboardKey, direction: Direction) -> CGRect
    func willShowPopup(for key: KeyboardKey, direction: Direction)
    func willHidePopup(for key: KeyboardKey)
}

class ShapeView: UIView {
    
    var shapeLayer: CAShapeLayer?
    
    override class var layerClass : AnyClass {
        return CAShapeLayer.self
    }
    
    var curve: UIBezierPath? {
        didSet {
            if let layer = self.shapeLayer {
                layer.path = curve?.cgPath
            }
        }
    }
    
    var fillColor: UIColor? {
        didSet {
            if let layer = self.shapeLayer {
                layer.fillColor = fillColor?.cgColor
            }
        }
    }
    
    var strokeColor: UIColor? {
        didSet {
            if let layer = self.shapeLayer {
                layer.strokeColor = strokeColor?.cgColor
            }
        }
    }
    
    var lineWidth: CGFloat? {
        didSet {
            if let layer = self.shapeLayer {
                if let lineWidth = self.lineWidth {
                    layer.lineWidth = lineWidth
                }
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.shapeLayer = self.layer as? CAShapeLayer
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class KeyboardKey: UIControl {
    
    weak var delegate: KeyboardKeyProtocol?
    
    var text: String {
        didSet {
            self.label.text = text
            self.label.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        }
    }
    
    var color: UIColor { didSet { updateColors() }}
    var underColor: UIColor { didSet { updateColors() }}
    var popupColor: UIColor { didSet { updateColors() }}
    var underOffset: CGFloat { didSet { updateColors() }}
    
    var textColor: UIColor { didSet { updateColors() }}
    
    var popupDirection: Direction?
    
    override var isHighlighted: Bool {
        didSet {
            updateColors()
        }
    }
    
    var label: UILabel
    var popupLabel: UILabel?
    
    var background: KeyboardKeyBackground
    var popup: KeyboardKeyBackground?
    var connector: KeyboardConnector?
    
    var displayView: ShapeView
    var underView: ShapeView?
    
    var shadowView: UIView
    var shadowLayer: CALayer
    
    init() {
        self.displayView = ShapeView()
        self.underView = ShapeView()
        
        self.shadowLayer = CAShapeLayer()
        self.shadowView = UIView()
        
        self.label = UILabel()
        self.text = ""
        
        self.color = UIColor.white
        self.underColor = UIColor(white: 0.67, alpha: 1.0)
        self.popupColor = UIColor.white
        self.underOffset = 1
        
        self.background = KeyboardKeyBackground(cornerRadius: 5, underOffset: self.underOffset)
        
        self.textColor = UIColor.black
        self.popupDirection = nil
        
        super.init(frame: CGRect.zero)
        
        self.addSubview(self.shadowView)
        self.shadowView.layer.addSublayer(self.shadowLayer)
        
        self.addSubview(self.displayView)
        if let underView = self.underView {
            self.addSubview(underView)
        }
        
        self.addSubview(self.background)
        self.background.addSubview(self.label)
        
        setupViews: do {
            self.displayView.isOpaque = false
            self.underView?.isOpaque = false
            
            self.displayView.isUserInteractionEnabled = false
            self.underView?.isUserInteractionEnabled = false
            self.shadowView.isUserInteractionEnabled = false
            self.background.isUserInteractionEnabled = false  // This was already set, but let's be explicit
            
            self.shadowLayer.shadowOpacity = Float(0.2)
            self.shadowLayer.shadowRadius = 4
            self.shadowLayer.shadowOffset = CGSize(width: 0, height: 3)
            
            self.label.textAlignment = NSTextAlignment.center
            self.label.baselineAdjustment = UIBaselineAdjustment.alignCenters
            self.label.font = self.label.font.withSize(22)
            self.label.adjustsFontSizeToFitWidth = true
            self.label.minimumScaleFactor = CGFloat(0.1)
            self.label.isUserInteractionEnabled = false
            self.label.numberOfLines = 1
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    var oldBounds: CGRect?
    override func layoutSubviews() {
        self.layoutPopupIfNeeded()
        
        let boundingBox = (self.popup != nil ? self.bounds.union(self.popup!.frame) : self.bounds)
        
        if self.bounds.width == 0 || self.bounds.height == 0 {
            return
        }
        if oldBounds != nil && boundingBox.size.equalTo(oldBounds!.size) {
            return
        }
        oldBounds = boundingBox
        
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.background.frame = self.bounds
        self.label.frame = self.bounds
        
        self.displayView.frame = boundingBox
        self.shadowView.frame = boundingBox
        self.underView?.frame = boundingBox
        
        CATransaction.commit()
        
        self.refreshViews()
    }
    
    func refreshViews() {
        self.refreshShapes()
        self.updateColors()
    }
    
    func refreshShapes() {
        self.background.setNeedsLayout()
        
        self.background.layoutIfNeeded()
        self.popup?.layoutIfNeeded()
        self.connector?.layoutIfNeeded()
        
        let testPath = UIBezierPath()
        
        let unitSquare = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        let addCurves = { (fromShape: KeyboardKeyBackground?, toPath: UIBezierPath) -> Void in
            if let shape = fromShape {
                let path = shape.fillPath
                let translatedUnitSquare = self.displayView.convert(unitSquare, from: shape)
                let transformFromShapeToView = CGAffineTransform(translationX: translatedUnitSquare.origin.x, y: translatedUnitSquare.origin.y)
                path?.apply(transformFromShapeToView)
                if path != nil { toPath.append(path!) }
            }
        }
        
        addCurves(self.popup, testPath)
        addCurves(self.connector, testPath)
        
        let shadowPath = UIBezierPath(cgPath: testPath.cgPath)
        
        addCurves(self.background, testPath)
        
        let underPath = self.background.underPath
        let translatedUnitSquare = self.displayView.convert(unitSquare, from: self.background)
        let transformFromShapeToView = CGAffineTransform(translationX: translatedUnitSquare.origin.x, y: translatedUnitSquare.origin.y)
        underPath?.apply(transformFromShapeToView)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if let _ = self.popup {
            self.shadowLayer.shadowPath = shadowPath.cgPath
        }
        
        self.underView?.curve = underPath
        self.displayView.curve = testPath
        
        CATransaction.commit()
    }
    
    func layoutPopupIfNeeded() {
        if self.popup != nil && self.popupDirection == nil {
            self.shadowView.isHidden = false
            
            self.popupDirection = Direction.up
            
            self.layoutPopup(self.popupDirection!)
            self.configurePopup(self.popupDirection!)
            
            self.delegate?.willShowPopup(for: self, direction: self.popupDirection!)
        }
        else {
            self.shadowView.isHidden = true
        }
    }
    
    func updateColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if self.isHighlighted {
            self.displayView.fillColor = UIColor(white: 0.85, alpha: 1.0)
        }
        else {
            self.displayView.fillColor = self.color
        }
        
        self.underView?.fillColor = self.underColor
        self.label.textColor = self.textColor
        self.popupLabel?.textColor = self.textColor
        
        if self.popup != nil {
            self.displayView.fillColor = self.popupColor
        }
        
        CATransaction.commit()
    }
    
    func layoutPopup(_ dir: Direction) {
        assert(self.popup != nil, "popup not found")
        
        if let popup = self.popup {
            if let delegate = self.delegate {
                let frame = delegate.popupFrame(for: self, direction: dir)
                popup.frame = frame
                popupLabel?.frame = popup.bounds
            }
            else {
                popup.frame = CGRect.zero
                popup.center = self.center
            }
        }
    }
    
    func configurePopup(_ direction: Direction) {
        assert(self.popup != nil, "popup not found")
        
        self.background.attach(direction)
        self.popup!.attach(direction.opposite())
        
        let kv = self.background
        let p = self.popup!
        
        self.connector?.removeFromSuperview()
        self.connector = KeyboardConnector(cornerRadius: 5, underOffset: self.underOffset, start: kv, end: p, startConnectable: kv, endConnectable: p, startDirection: direction, endDirection: direction.opposite())
        self.connector!.layer.zPosition = -1
        self.addSubview(self.connector!)
    }
    
    func showPopup() {
        if self.popup == nil {
            self.layer.zPosition = 1000
            
            let popup = KeyboardKeyBackground(cornerRadius: 9.0, underOffset: self.underOffset)
            self.popup = popup
            self.addSubview(popup)
            
            let popupLabel = UILabel()
            popupLabel.textAlignment = self.label.textAlignment
            popupLabel.baselineAdjustment = self.label.baselineAdjustment
            popupLabel.font = self.label.font.withSize(44)
            popupLabel.adjustsFontSizeToFitWidth = self.label.adjustsFontSizeToFitWidth
            popupLabel.minimumScaleFactor = CGFloat(0.1)
            popupLabel.isUserInteractionEnabled = false
            popupLabel.numberOfLines = 1
            popupLabel.frame = popup.bounds
            popupLabel.text = self.label.text
            popupLabel.textColor = self.textColor
            popup.addSubview(popupLabel)
            self.popupLabel = popupLabel
            
            self.label.isHidden = true
            
            // Force layout immediately
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    func hidePopup() {
        if self.popup != nil {
            self.delegate?.willHidePopup(for: self)
            
            self.popupLabel?.removeFromSuperview()
            self.popupLabel = nil
            
            self.connector?.removeFromSuperview()
            self.connector = nil
            
            self.popup?.removeFromSuperview()
            self.popup = nil
            
            self.label.isHidden = false
            self.background.attach(nil)
            
            self.layer.zPosition = 0
            
            self.popupDirection = nil
        }
    }
}
