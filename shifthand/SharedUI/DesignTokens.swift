//
//  DesignTokens.swift
//  shifthand
//
//  Authoritative Design Tokens conforming strictly to Docs/UI_STANDARDS.md.
//  Note: Dark mode colors are derived programmatically to ensure contrast and
//  are explicitly marked "derived, not from Guide".
//

import SwiftUI

// MARK: - Color Tokens

extension Color {
    // Primary & Accent Brand Tokens
    public static let shPrimaryTeal = Color(
        lightHex: "#0E7C86",
        darkHex: "#149CA8" // derived, not from Guide
    )
    public static let shDarkTeal = Color(
        lightHex: "#0A5961",
        darkHex: "#0E7C86" // derived, not from Guide
    )
    public static let shAccentAmber = Color(
        lightHex: "#F59E0B",
        darkHex: "#FBBF24" // derived, not from Guide
    )

    // Background Tokens
    public static let shBackgroundPrimary = Color(
        lightHex: "#F6F8FA",
        darkHex: "#0B0F17" // derived, not from Guide
    )
    public static let shBackgroundCard = Color(
        lightHex: "#FFFFFF",
        darkHex: "#151E2E" // derived, not from Guide
    )

    // Border Tokens
    public static let shBorderDefault = Color(
        lightHex: "#E2E8F0",
        darkHex: "#222F43" // derived, not from Guide
    )

    // Text Hierarchy Tokens
    public static let shTextPrimary = Color(
        lightHex: "#0F172A",
        darkHex: "#F8FAFC" // derived, not from Guide
    )
    public static let shTextSecondary = Color(
        lightHex: "#475569",
        darkHex: "#94A3B8" // derived, not from Guide
    )

    // Status Semantic Tokens
    public static let shStatusGreen = Color(
        lightHex: "#10B981",
        darkHex: "#34D399" // derived, not from Guide
    )
    public static let shStatusRed = Color(
        lightHex: "#EF4444",
        darkHex: "#F87171" // derived, not from Guide
    )
    public static let shStatusBlue = Color(
        lightHex: "#3B82F6",
        darkHex: "#60A5FA" // derived, not from Guide
    )
    public static let shStatusPurple = Color(
        lightHex: "#8B5CF6",
        darkHex: "#A78BFA" // derived, not from Guide
    )
    public static let shStatusGrey = Color(
        lightHex: "#64748B",
        darkHex: "#94A3B8" // derived, not from Guide
    )
}

// MARK: - Layout & Dimension Tokens

public enum SHMetrics {
    /// 16 pt corner radius for cards, dialogs, and modal containers.
    public static let cardCornerRadius: CGFloat = 16

    /// 12 pt corner radius for primary buttons and large interactive controls.
    public static let buttonCornerRadius: CGFloat = 12

    /// 8 pt corner radius for status chips and tags.
    public static let chipCornerRadius: CGFloat = 8

    /// Minimum accessibility touch target: 44 x 44 pt.
    public static let minTouchTarget: CGFloat = 44

    /// 8 pt spacing grid units.
    public static let spacingXXS: CGFloat = 4
    public static let spacingXS: CGFloat = 8
    public static let spacingSM: CGFloat = 12
    public static let spacingMD: CGFloat = 16
    public static let spacingLG: CGFloat = 24
    public static let spacingXL: CGFloat = 32
}

// MARK: - Corner Radius Tokens

public enum SHCornerRadius {
    /// 8 pt for status chips and compact tags.
    public static let small: CGFloat = 8
    /// 12 pt for buttons, cards, and interactive controls.
    public static let medium: CGFloat = 12
    /// 16 pt for primary cards and modal sheets.
    public static let large: CGFloat = 16
}

// MARK: - Private Hex Initializers (Strictly Internal to DesignTokens)

private extension Color {
    init(lightHex: String, darkHex: String) {
        self.init(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(hex: darkHex)
            } else {
                return UIColor(hex: lightHex)
            }
        })
    }
}

private extension UIColor {
    convenience init(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.remove(at: cleanHex.startIndex)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)

        let r, g, b, a: CGFloat
        if cleanHex.count == 6 {
            r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgbValue & 0x0000FF) / 255.0
            a = 1.0
        } else if cleanHex.count == 8 {
            r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgbValue & 0x000000FF) / 255.0
        } else {
            r = 0; g = 0; b = 0; a = 1.0
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
