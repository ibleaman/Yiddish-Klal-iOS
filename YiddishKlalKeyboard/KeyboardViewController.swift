//
//  KeyboardViewController.swift
//  Yiddish Klal - A Standard Yiddish keyboard layout for iOS
//  Created by Isaac L. Bleaman (bleaman@berkeley.edu)
//
//  Character preview system adapted from tasty-imitation-keyboard
//  Copyright (c) 2014 Alexei Baboulevitch (archagon)
//
//  Copyright © 2026 Isaac L. Bleaman
//  Distributed by Leyenzal - A Yiddish Literacy Project (leyenzal.org)
//
//  See LICENSE.txt for full license terms
//

import UIKit

class KeyboardViewController: UIInputViewController, KeyboardKeyProtocol {
    
    var isSymbolMode = false
    var isShifted = false
    var shiftButton: UIButton?
    var spaceButton: UIButton?
    var keyboardStack: UIStackView?
    var spacebarTimer: Timer?
    var deleteTimer: Timer?
    var popupView: KeyPopupView?
    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    let kDeleteEntireGrapheme = "kDeleteEntireGrapheme"
    
    // Backspace behavior setting
    var deleteEntireGrapheme: Bool {
        return UserDefaults(suiteName: "group.org.leyenzal.yiddishklal")?.bool(forKey: kDeleteEntireGrapheme) ?? false
    }
    
    // Popup delay management
    var keyWithDelayedPopup: KeyboardKey?
    var popupDelayTimer: Timer?
    
    // Custom popup options for specific keys
    let customPopups: [String: [String]] = [
        "ב": ["ב", "בֿ", "בּ"],
        "אָ": ["אָ", "ױ", "א"],
        "ס": ["ס", "ת", "שׂ"],
        "כ": ["כ", "ך", "כּ"]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear

        let keyboard = createLettersKeyboard()
        view.addSubview(keyboard)
        self.keyboardStack = keyboard
        
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboard.topAnchor.constraint(equalTo: view.topAnchor),
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            keyboard.heightAnchor.constraint(greaterThanOrEqualToConstant: 270)
        ])
        
        hapticFeedback.prepare()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isSymbolMode {
            animateSpacebarLabel()
        }
    }
    
    // MARK: - KeyboardKeyProtocol
    
    func popupFrame(for key: KeyboardKey, direction: Direction) -> CGRect {
        let actualScreenWidth = (UIScreen.main.nativeBounds.size.width / UIScreen.main.nativeScale)
        let isWideScreen = actualScreenWidth >= 400
        
        let popupWidth: CGFloat = key.bounds.width + 24
        let popupHeight: CGFloat = isWideScreen ? 76 : 70
        
        // Popup is a subview of the key, so frame is relative to the key itself
        // Center the popup horizontally on the key
        let popupX = (key.bounds.width - popupWidth) / 2
        
        // Position popup above the key
        let popupY = -popupHeight + 8
        
        // Create the frame in the key's coordinate space
        let frame = CGRect(x: popupX, y: popupY, width: popupWidth, height: popupHeight)
        
        return frame
    }
    
    func willShowPopup(for key: KeyboardKey, direction: Direction) {
        // Called when popup is about to show
    }
    
    func willHidePopup(for key: KeyboardKey) {
        // Called when popup is about to hide
    }
    
    // MARK: - Keyboard Creation
    
    func createLettersKeyboard() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.layoutMargins = UIEdgeInsets(top: 60, left: 4, bottom: 8, right: 4)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        stackView.addArrangedSubview(createRow1())
        stackView.addArrangedSubview(createRow2())
        stackView.addArrangedSubview(createRow3())
        stackView.addArrangedSubview(createLettersBottomRow())
        
        return stackView
    }
    
    func createRow1() -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .fill
        rowStack.distribution = .fillEqually
        rowStack.spacing = 3
        
        let unshifted = ["ק", "ש", "ע", "ר", "ט", "ײַ", "ו", "י", "אָ", "פּ"]
        let shifted = ["כּ", "שׂ", "ײ", "טש", "תּ", "ױ", "וּ", "יִ", "ױ", "פ"]
        
        for i in 0..<unshifted.count {
            let button = makeDualKey(unshifted: unshifted[i], shifted: shifted[i])
            rowStack.addArrangedSubview(button)
        }
        
        return rowStack
    }
    
    func createRow2() -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .fill
        rowStack.distribution = .fillEqually
        rowStack.spacing = 3
        
        let unshifted = ["אַ", "ס", "ד", "פֿ", "ג", "ה", "ײ", "ק", "ל"]
        let shifted = ["א", "ת", "דזש", "ף", "דזש", "ח", "דזש", "כּ", "ל"]
        
        for i in 0..<unshifted.count {
            let button = makeDualKey(unshifted: unshifted[i], shifted: shifted[i])
            rowStack.addArrangedSubview(button)
        }
        
        return rowStack
    }
    
    func createRow3() -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .fill
        rowStack.spacing = 3
        
        let shiftBtn = makeShiftKey()
        rowStack.addArrangedSubview(shiftBtn)
        self.shiftButton = shiftBtn
        
        let unshifted = ["ז", "כ", "צ", "װ", "ב", "נ", "מ"]
        let shifted = ["זש", "ך", "ץ", "בֿ", "בּ", "ן", "ם"]
        
        let lettersStack = UIStackView()
        lettersStack.axis = .horizontal
        lettersStack.alignment = .fill
        lettersStack.distribution = .fillEqually
        lettersStack.spacing = 3
        
        for i in 0..<unshifted.count {
            let button = makeDualKey(unshifted: unshifted[i], shifted: shifted[i])
            lettersStack.addArrangedSubview(button)
        }
        
        rowStack.addArrangedSubview(lettersStack)
        
        let deleteButton = makeSpecialKey("⌦", action: #selector(deletePressed))
        rowStack.addArrangedSubview(deleteButton)
        
        shiftBtn.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        if let firstLetter = lettersStack.arrangedSubviews.first {
            NSLayoutConstraint.activate([
                shiftBtn.widthAnchor.constraint(equalTo: firstLetter.widthAnchor, multiplier: 1.7),
                deleteButton.widthAnchor.constraint(equalTo: firstLetter.widthAnchor, multiplier: 1.7)
            ])
        }
        
        return rowStack
    }
    
    func createLettersBottomRow() -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .fill
        rowStack.spacing = 3
        rowStack.distribution = .fill
        
        let symbolsButton = makeSpecialKey("123", action: #selector(switchToSymbols))
        rowStack.addArrangedSubview(symbolsButton)
        
        let spaceBtn = makeSpecialKey("", action: #selector(spacePressed))
        self.spaceButton = spaceBtn
        rowStack.addArrangedSubview(spaceBtn)
        
        let periodButton = makeSpecialKey(".", action: #selector(periodPressed))
        rowStack.addArrangedSubview(periodButton)
        
        let returnButton = makeReturnKey()
        rowStack.addArrangedSubview(returnButton)
        
        symbolsButton.translatesAutoresizingMaskIntoConstraints = false
        periodButton.translatesAutoresizingMaskIntoConstraints = false
        returnButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            symbolsButton.widthAnchor.constraint(equalTo: periodButton.widthAnchor),
            periodButton.widthAnchor.constraint(equalTo: returnButton.widthAnchor),
            spaceBtn.widthAnchor.constraint(equalTo: symbolsButton.widthAnchor, multiplier: 3.5)
        ])
        
        return rowStack
    }
    
    func createSymbolsKeyboard() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.layoutMargins = UIEdgeInsets(top: 60, left: 4, bottom: 8, right: 4)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        stackView.addArrangedSubview(createSymbolsRow1())
        stackView.addArrangedSubview(createSymbolsRow2())
        stackView.addArrangedSubview(createSymbolsRow3())
        stackView.addArrangedSubview(createSymbolsBottomRow())
        
        return stackView
    }
    
    func createSymbolsRow1() -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .fill
        rowStack.distribution = .fillEqually
        rowStack.spacing = 3
        
        let unshifted = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        let shifted = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"]
        
        for i in 0..<unshifted.count {
            let button = makeDualKey(unshifted: unshifted[i], shifted: shifted[i])
            rowStack.addArrangedSubview(button)
        }
        
        return rowStack
    }
    
    func createSymbolsRow2() -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .fill
        rowStack.distribution = .fillEqually
        rowStack.spacing = 3
        
        let typedUnshifted = ["־", "-", "/", ":", ";", ")", "(", "=", "+"]
        let typedShifted = ["~", "_", "\\", "]", "[", "}", "{", "≠", "±"]
        
        let displayUnshifted = ["־", "-", "/", ":", ";", "(", ")", "=", "+"]
        let displayShifted = ["~", "_", "\\", "[", "]", "{", "}", "≠", "±"]
        
        for i in 0..<typedUnshifted.count {
            let button = makeRTLDualKey(
                displayUnshifted: displayUnshifted[i],
                displayShifted: displayShifted[i],
                typedUnshifted: typedUnshifted[i],
                typedShifted: typedShifted[i]
            )
            rowStack.addArrangedSubview(button)
        }
        
        return rowStack
    }
    
    func createSymbolsRow3() -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .fill
        rowStack.spacing = 3
        
        let shiftBtn = makeShiftKey()
        rowStack.addArrangedSubview(shiftBtn)
        self.shiftButton = shiftBtn
        
        let openQuote = "\u{201E}"
        let closeQuote = "\u{201C}"
        let unshifted = [".", ",", "?", "!", "'", "\"", closeQuote, openQuote]
        let shifted = ["<", ">", "¿", "¡", "`", "′", "«", "»"]
        
        let punctStack = UIStackView()
        punctStack.axis = .horizontal
        punctStack.alignment = .fill
        punctStack.distribution = .fillEqually
        punctStack.spacing = 3
        
        for i in 0..<unshifted.count {
            let button = makeDualKey(unshifted: unshifted[i], shifted: shifted[i])
            punctStack.addArrangedSubview(button)
        }
        
        rowStack.addArrangedSubview(punctStack)
        
        let deleteButton = makeSpecialKey("⌦", action: #selector(deletePressed))
        rowStack.addArrangedSubview(deleteButton)
        
        shiftBtn.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        if let firstButton = punctStack.arrangedSubviews.first {
            NSLayoutConstraint.activate([
                shiftBtn.widthAnchor.constraint(equalTo: firstButton.widthAnchor, multiplier: 1.7),
                deleteButton.widthAnchor.constraint(equalTo: firstButton.widthAnchor, multiplier: 1.7)
            ])
        }
        
        return rowStack
    }
    
    func createSymbolsBottomRow() -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .fill
        rowStack.spacing = 3
        rowStack.distribution = .fill
        
        let lettersButton = makeSpecialKey("א־ת", action: #selector(switchToLetters))
        rowStack.addArrangedSubview(lettersButton)
        
        let spaceBtn = makeSpecialKey("", action: #selector(spacePressed))
        self.spaceButton = spaceBtn
        rowStack.addArrangedSubview(spaceBtn)
        
        let periodButton = makeSpecialKey(".", action: #selector(periodPressed))
        rowStack.addArrangedSubview(periodButton)
        
        let returnButton = makeReturnKey()
        rowStack.addArrangedSubview(returnButton)
        
        lettersButton.translatesAutoresizingMaskIntoConstraints = false
        periodButton.translatesAutoresizingMaskIntoConstraints = false
        returnButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            lettersButton.widthAnchor.constraint(equalTo: periodButton.widthAnchor),
            periodButton.widthAnchor.constraint(equalTo: returnButton.widthAnchor),
            spaceBtn.widthAnchor.constraint(equalTo: lettersButton.widthAnchor, multiplier: 3.5)
        ])
        
        return rowStack
    }
    
    // MARK: - Key Creation
    
    func makeDualKey(unshifted: String, shifted: String) -> KeyboardKey {
        let button = KeyboardKey()
        button.delegate = self
        button.text = unshifted
        button.accessibilityIdentifier = unshifted + "|" + shifted
        
        // Touch event handling
        button.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(keyTouchUp(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(keyTouchCancel(_:)), for: [.touchUpOutside, .touchDragOutside, .touchCancel])
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        button.addGestureRecognizer(longPress)
        
        return button
    }
    
    func makeRTLDualKey(displayUnshifted: String, displayShifted: String, typedUnshifted: String, typedShifted: String) -> KeyboardKey {
        let button = KeyboardKey()
        button.delegate = self
        button.text = displayUnshifted
        button.accessibilityIdentifier = typedUnshifted + "|" + typedShifted + "|" + displayUnshifted + "|" + displayShifted
        
        // Touch event handling
        button.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(keyTouchUp(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(keyTouchCancel(_:)), for: [.touchUpOutside, .touchDragOutside, .touchCancel])
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        button.addGestureRecognizer(longPress)
        
        return button
    }
    
    func makeShiftKey() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("⇧", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor(white: 0.67, alpha: 1.0)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(shiftTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(shiftPressed), for: .touchUpInside)
        button.addTarget(self, action: #selector(shiftTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return button
    }
    
    func makeSpecialKey(_ label: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(label, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor(white: 0.67, alpha: 1.0)
        button.layer.cornerRadius = 5
        
        // Visual feedback
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        button.addTarget(self, action: action, for: .touchUpInside)
        
        if label == "⌦" {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleDeleteLongPress(_:)))
            longPress.minimumPressDuration = 0.5
            button.addGestureRecognizer(longPress)
        }
        
        return button
    }
    
    func makeReturnKey() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("↵", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(returnPressed), for: .touchUpInside)
        return button
    }
    
    func animateSpacebarLabel() {
        guard let spaceBtn = spaceButton else { return }
        
        UIView.transition(with: spaceBtn, duration: 0.3, options: .transitionCrossDissolve) {
            spaceBtn.setTitle("Yiddish Klal", for: .normal)
        }
        
        spacebarTimer?.invalidate()
        spacebarTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            guard let spaceBtn = self?.spaceButton else { return }
            UIView.transition(with: spaceBtn, duration: 0.3, options: .transitionCrossDissolve) {
                spaceBtn.setTitle("", for: .normal)
            }
        }
    }
    
    // MARK: - Button Visual Feedback

    @objc func buttonTouchDown(_ sender: UIButton) {
        sender.backgroundColor = .white
    }

    @objc func buttonTouchUp(_ sender: UIButton) {
        sender.backgroundColor = UIColor(white: 0.67, alpha: 1.0)
    }

    @objc func shiftTouchDown(_ sender: UIButton) {
        if !isShifted {
            sender.backgroundColor = .white
        }
    }

    @objc func shiftTouchUp(_ sender: UIButton) {
        // toggleShift() will set the correct color
    }
    
    // MARK: - Character Preview

    // Track the currently active popup
    var currentPopupKey: KeyboardKey?

    @objc func keyTouchDown(_ sender: KeyboardKey) {
        // Cancel any delayed popup hiding
        popupDelayTimer?.invalidate()
        popupDelayTimer = nil
        
        // Immediately hide any other key's popup
        if let previousKey = currentPopupKey, previousKey != sender {
            previousKey.hidePopup()
        }
        
        // Track this as the current popup key
        currentPopupKey = sender
        keyWithDelayedPopup = sender
        
        // Update key text for current shift state
        updateKeyText(sender)
        
        // Show popup
        sender.showPopup()
        sender.setNeedsLayout()
        
        // Haptic feedback
        hapticFeedback.impactOccurred()
    }

    @objc func keyTouchUp(_ sender: KeyboardKey) {
        // Handle key press (type character)
        guard let id = sender.accessibilityIdentifier else { return }
        let parts = id.components(separatedBy: "|")
        
        if parts.count == 4 {
            // RTL key
            let char = isShifted ? parts[1] : parts[0]
            textDocumentProxy.insertText(char)
        } else if parts.count == 2 {
            // Normal key
            let char = isShifted ? parts[1] : parts[0]
            textDocumentProxy.insertText(char)
        }
        
        if isShifted {
            toggleShift()
        }
        
        // Hide popup with delay
        hidePopupDelay(sender)
    }

    @objc func keyTouchCancel(_ sender: KeyboardKey) {
        hidePopupDelay(sender)
    }

    func hidePopupDelay(_ sender: KeyboardKey) {
        popupDelayTimer?.invalidate()
        
        if sender != keyWithDelayedPopup {
            keyWithDelayedPopup?.hidePopup()
            if keyWithDelayedPopup == currentPopupKey {
                currentPopupKey = nil
            }
            keyWithDelayedPopup = sender
        }
        
        if sender.popup != nil {
            popupDelayTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(hidePopupCallback), userInfo: nil, repeats: false)
        }
    }

    @objc func hidePopupCallback() {
        keyWithDelayedPopup?.hidePopup()
        if keyWithDelayedPopup == currentPopupKey {
            currentPopupKey = nil
        }
        keyWithDelayedPopup = nil
        popupDelayTimer = nil
    }
    
    func updateKeyText(_ key: KeyboardKey) {
        guard let id = key.accessibilityIdentifier else { return }
        let parts = id.components(separatedBy: "|")
        
        if parts.count == 4 {
            key.text = isShifted ? parts[3] : parts[2]
        } else if parts.count == 2 {
            key.text = isShifted ? parts[1] : parts[0]
        }
    }
    
    // MARK: - Long Press Popup Menu
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? KeyboardKey,
              let id = button.accessibilityIdentifier else { return }
        
        let parts = id.components(separatedBy: "|")
        
        let chars: [String]
        if parts.count == 4 {
            chars = [parts[0], parts[1]]
        } else if parts.count == 2 {
            chars = parts
        } else {
            return
        }
        
        let currentChar = isShifted ? chars[1] : chars[0]
        
        var options: [String]
        if let customOptions = customPopups[currentChar] {
            options = customOptions
            if options.count > 1 {
                let defaultChar = options.removeFirst()
                options.append(defaultChar)
            }
        } else {
            if isShifted {
                options = [chars[0], chars[1]]
            } else {
                options = [chars[1], chars[0]]
            }
        }
        
        switch gesture.state {
        case .began:
            // Hide any existing character preview popup
            hidePopupCallback()
            currentPopupKey = nil
            
            showPopupMenu(options: options, above: button)
            hapticFeedback.impactOccurred()
            
        case .changed:
            updatePopupSelection(gesture: gesture)
            
        case .ended:
            if let selectedChar = popupView?.selectedCharacter {
                textDocumentProxy.insertText(selectedChar)
                hapticFeedback.impactOccurred()
            }
            hidePopupMenu()
            
        case .cancelled, .failed:
            hidePopupMenu()
            
        default:
            break
        }
    }
    
    func showPopupMenu(options: [String], above button: KeyboardKey) {
        popupView?.removeFromSuperview()
        
        let popup = KeyPopupView(options: options)
        view.addSubview(popup)
        popupView = popup
        
        let popupHeight: CGFloat = 50
        let popupWidth: CGFloat = CGFloat(options.count) * 45
        
        let buttonFrame = button.convert(button.bounds, to: view)
        
        var popupX = buttonFrame.midX - popupWidth / 2
        
        if popupX < 5 {
            popupX = 5
        } else if popupX + popupWidth > view.bounds.width - 5 {
            popupX = view.bounds.width - popupWidth - 5
        }
        
        // ALWAYS position above the button (now that we have top buffer space)
        let popupY = buttonFrame.minY - popupHeight - 5
        
        popup.frame = CGRect(
            x: popupX,
            y: popupY,
            width: popupWidth,
            height: popupHeight
        )
        
        view.bringSubviewToFront(popup)
        
        popup.alpha = 0
        popup.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.15) {
            popup.alpha = 1
            popup.transform = .identity
        }
    }
    
    func updatePopupSelection(gesture: UILongPressGestureRecognizer) {
        guard let popup = popupView else { return }
        
        let location = gesture.location(in: popup)
        popup.updateSelection(at: location)
    }
    
    func hidePopupMenu() {
        guard let popup = popupView else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            popup.alpha = 0
            popup.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            popup.removeFromSuperview()
            self.popupView = nil
        }
    }
    
    // MARK: - Delete Repeat
    
    @objc func handleDeleteLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            startDeletingRepeatedly()
        case .ended, .cancelled, .failed:
            stopDeletingRepeatedly()
        default:
            break
        }
    }
    
    func startDeletingRepeatedly() {
        // Delete once immediately
        if let selectedText = textDocumentProxy.selectedText, !selectedText.isEmpty {
            // Just delete the selection
            textDocumentProxy.deleteBackward()
        }
        else if deleteEntireGrapheme {
            if let documentContext = textDocumentProxy.documentContextBeforeInput {
                if let lastChar = documentContext.last {
                    let scalarCount = String(lastChar).unicodeScalars.count
                    for _ in 0..<scalarCount {
                        textDocumentProxy.deleteBackward()
                    }
                }
            }
        } else {
            textDocumentProxy.deleteBackward()
        }
        hapticFeedback.impactOccurred()
        
        deleteTimer?.invalidate()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Check for selection on each repeat
            if let selectedText = self.textDocumentProxy.selectedText, !selectedText.isEmpty {
                self.textDocumentProxy.deleteBackward()
            }
            else if self.deleteEntireGrapheme {
                if let documentContext = self.textDocumentProxy.documentContextBeforeInput {
                    if let lastChar = documentContext.last {
                        let scalarCount = String(lastChar).unicodeScalars.count
                        for _ in 0..<scalarCount {
                            self.textDocumentProxy.deleteBackward()
                        }
                    }
                }
            } else {
                self.textDocumentProxy.deleteBackward()
            }
            self.hapticFeedback.impactOccurred()
        }
    }
    
    func stopDeletingRepeatedly() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }
    
    // MARK: - Mode Switching
    
    @objc func switchToSymbols() {
        isSymbolMode = true
        isShifted = false
        
        keyboardStack?.removeFromSuperview()
        
        let symbolsKeyboard = createSymbolsKeyboard()
        self.keyboardStack = symbolsKeyboard
        
        view.addSubview(symbolsKeyboard)
        
        symbolsKeyboard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            symbolsKeyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            symbolsKeyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            symbolsKeyboard.topAnchor.constraint(equalTo: view.topAnchor),
            symbolsKeyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            symbolsKeyboard.heightAnchor.constraint(greaterThanOrEqualToConstant: 270)
        ])
        
        symbolsKeyboard.layoutIfNeeded()
    }
    
    @objc func switchToLetters() {
        isSymbolMode = false
        isShifted = false
        
        let lettersKeyboard = createLettersKeyboard()
        view.addSubview(lettersKeyboard)
        
        lettersKeyboard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lettersKeyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lettersKeyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lettersKeyboard.topAnchor.constraint(equalTo: view.topAnchor),
            lettersKeyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            lettersKeyboard.heightAnchor.constraint(greaterThanOrEqualToConstant: 270)
        ])
        
        lettersKeyboard.layoutIfNeeded()
        
        keyboardStack?.removeFromSuperview()
        self.keyboardStack = lettersKeyboard
    }
    
    // MARK: - Key Actions
    
    @objc func shiftPressed() {
        toggleShift()
    }
    
    func toggleShift() {
        isShifted.toggle()
        
        if isShifted {
            shiftButton?.backgroundColor = .white
            shiftButton?.setTitleColor(.systemBlue, for: .normal)
        } else {
            shiftButton?.backgroundColor = UIColor(white: 0.67, alpha: 1.0)
            shiftButton?.setTitleColor(.black, for: .normal)
        }
        
        let allKeys = keyboardStack?.arrangedSubviews.compactMap { row -> [KeyboardKey] in
            if let stack = row as? UIStackView {
                return stack.arrangedSubviews.compactMap { view -> [KeyboardKey] in
                    if let key = view as? KeyboardKey {
                        return [key]
                    } else if let innerStack = view as? UIStackView {
                        return innerStack.arrangedSubviews.compactMap { $0 as? KeyboardKey }
                    }
                    return []
                }.flatMap { $0 }
            }
            return []
        }.flatMap { $0 } ?? []
        
        for key in allKeys {
            updateKeyText(key)
        }
    }
    
    @objc func spacePressed() {
        textDocumentProxy.insertText(" ")
        hapticFeedback.impactOccurred()
    }
    
    @objc func periodPressed() {
        textDocumentProxy.insertText(".")
        hapticFeedback.impactOccurred()
    }
    
    @objc func deletePressed() {
        // If there's selected text, just delete it regardless of grapheme setting
        if let selectedText = textDocumentProxy.selectedText, !selectedText.isEmpty {
            textDocumentProxy.deleteBackward()
        }
        else if deleteEntireGrapheme {
            // Delete entire grapheme cluster (letter + all diacritics)
            if let documentContext = textDocumentProxy.documentContextBeforeInput {
                if let lastChar = documentContext.last {
                    let scalarCount = String(lastChar).unicodeScalars.count
                    for _ in 0..<scalarCount {
                        textDocumentProxy.deleteBackward()
                    }
                }
            }
        } else {
            // Delete one component at a time (diacritic first, then letter)
            textDocumentProxy.deleteBackward()
        }
        hapticFeedback.impactOccurred()
    }
    
    @objc func returnPressed() {
        textDocumentProxy.insertText("\n")
        hapticFeedback.impactOccurred()
    }
}

// MARK: - Key Popup View

class KeyPopupView: UIView {
    var options: [String]
    var selectedIndex: Int
    var optionButtons: [UIView] = []
    
    var selectedCharacter: String? {
        return options[selectedIndex]
    }
    
    init(options: [String]) {
        self.options = options
        self.selectedIndex = options.count - 1
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        for (index, option) in options.enumerated() {
            let container = UIView()
            container.backgroundColor = index == selectedIndex ? UIColor.systemBlue.withAlphaComponent(0.2) : .clear
            
            let label = UILabel()
            label.text = option
            label.font = UIFont.systemFont(ofSize: 24, weight: .regular)
            label.textAlignment = .center
            label.textColor = .black
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
            
            stackView.addArrangedSubview(container)
            optionButtons.append(container)
        }
    }
    
    func updateSelection(at point: CGPoint) {
        let buttonWidth = bounds.width / CGFloat(options.count)
        let newIndex = min(max(0, Int(point.x / buttonWidth)), options.count - 1)
        
        if newIndex != selectedIndex {
            optionButtons[selectedIndex].backgroundColor = .clear
            
            selectedIndex = newIndex
            optionButtons[selectedIndex].backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        }
    }
}
