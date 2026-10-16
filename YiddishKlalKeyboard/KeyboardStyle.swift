//
//  KeyboardStyle.swift
//  Yiddish Klal - A Standard Yiddish keyboard layout for iOS
//
//  See LICENSE.txt for full license terms
//

import UIKit

enum KeyboardStyle {
    static let usesLiquidGlass: Bool = {
        if #available(iOS 26, *) { return true }
        return false
    }()

    static let keyCornerRadius: CGFloat = usesLiquidGlass ? 8 : 5

    static let keyHeight: CGFloat = 43
    static let keySpacing: CGFloat = 6
    static let rowSpacing: CGFloat = 11
    static let sideInset: CGFloat = 6.5
    static let wideKeyUnits: CGFloat = 1.3
    static let returnKeyUnits: CGFloat = 2.78
    static let iconPointSize: CGFloat = 15

    // iOS 27 sets its own bottom row lower than a custom keyboard can draw.
    static let bottomInset: CGFloat = {
        if #available(iOS 27, *) { return 0 }
        return 3
    }()
}

extension UIColor {
    private static let usesLiquidGlass = KeyboardStyle.usesLiquidGlass

    private static func keyboard(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }

    private static func white(_ alpha: CGFloat) -> UIColor {
        UIColor(white: 1, alpha: alpha)
    }

    static let keyFill: UIColor = usesLiquidGlass
        ? keyboard(light: .white, dark: white(0.165))
        : keyboard(light: .white, dark: white(0.3))

    static let specialKeyFill: UIColor = usesLiquidGlass
        ? keyFill
        : keyboard(
            light: UIColor(red: 171.0 / 255, green: 177.0 / 255, blue: 186.0 / 255, alpha: 1),
            dark: white(0.13))

    static let keyFillPressed: UIColor = usesLiquidGlass
        ? keyboard(light: white(0.6), dark: white(0.165 * 0.6))
        : specialKeyFill

    static let specialKeyFillPressed: UIColor = usesLiquidGlass ? keyFillPressed : keyFill

    static let keyPopupFill = keyboard(light: .white, dark: UIColor(white: 107.0 / 255, alpha: 1))

    static let keyUnder: UIColor = usesLiquidGlass
        ? .clear
        : keyboard(light: UIColor(white: 0, alpha: 0.3), dark: UIColor(white: 0, alpha: 0.7))

    static let keyText = keyboard(light: .black, dark: .white)

    static let shiftOnFill: UIColor = usesLiquidGlass ? specialKeyFill : .white

    static let shiftOnIcon: UIColor = usesLiquidGlass ? keyText : .black
}
