//
//  StatusChip.swift
//  shifthand
//
//  Semantic status indicator complying strictly with Docs/UI_STANDARDS.md.
//  MANDATORY ACCESSIBILITY RULE: MUST always display Icon + Text + Colour.
//

import SwiftUI

public enum StatusChipStyle: Sendable, Equatable {
    case green
    case amber
    case red
    case grey
    case teal
    case blue
    case purple

    public var foregroundColor: Color {
        switch self {
        case .green: return .shStatusGreen
        case .amber: return .shAccentAmber
        case .red: return .shStatusRed
        case .grey: return .shStatusGrey
        case .teal: return .shPrimaryTeal
        case .blue: return .shStatusBlue
        case .purple: return .shStatusPurple
        }
    }

    public var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }

    public var borderColor: Color {
        foregroundColor.opacity(0.28)
    }
}

public struct StatusChip: View {
    public let title: String
    public let systemImage: String
    public let style: StatusChipStyle

    public init(title: String, systemImage: String, style: StatusChipStyle) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .bold))
                .accessibilityHidden(true)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(style.foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius)
                .fill(style.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius)
                .stroke(style.borderColor, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(title)")
    }
}

// MARK: - Standard Presets
extension StatusChip {
    public static func confirmed(_ text: String = "Confirmed") -> StatusChip {
        StatusChip(title: text, systemImage: "checkmark.circle.fill", style: .green)
    }

    public static func arrived(_ text: String = "Arrived") -> StatusChip {
        StatusChip(title: text, systemImage: "checkmark.circle.fill", style: .green)
    }

    public static func completed(_ text: String = "Completed") -> StatusChip {
        StatusChip(title: text, systemImage: "checkmark.circle.fill", style: .green)
    }

    public static func cancelled(_ text: String = "Cancelled") -> StatusChip {
        StatusChip(title: text, systemImage: "xmark.circle.fill", style: .grey)
    }

    public static func lateCancel(_ text: String = "Late Cancel") -> StatusChip {
        StatusChip(title: text, systemImage: "exclamationmark.circle.fill", style: .amber)
    }

    public static func unverified(_ text: String = "Unverified") -> StatusChip {
        StatusChip(title: text, systemImage: "clock.fill", style: .amber)
    }

    public static func noShow(_ text: String = "No-Show") -> StatusChip {
        StatusChip(title: text, systemImage: "person.crop.circle.badge.xmark", style: .red)
    }

    public static func missing(_ text: String = "Missing") -> StatusChip {
        StatusChip(title: text, systemImage: "clock.badge.exclamationmark", style: .red)
    }

    public static func draft(_ text: String = "Draft") -> StatusChip {
        StatusChip(title: text, systemImage: "pencil.circle.fill", style: .grey)
    }

    public static func published(_ text: String = "Published") -> StatusChip {
        StatusChip(title: text, systemImage: "globe", style: .teal)
    }

    public static func live(_ text: String = "Live") -> StatusChip {
        StatusChip(title: text, systemImage: "bolt.circle.fill", style: .green)
    }
}

// MARK: - Previews (Light and Dark)
#Preview("StatusChip Presets - Light") {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            StatusChip.confirmed()
            StatusChip.arrived()
            StatusChip.completed()
        }
        HStack {
            StatusChip.unverified()
            StatusChip.lateCancel()
            StatusChip.cancelled()
        }
        HStack {
            StatusChip.noShow()
            StatusChip.missing()
            StatusChip.draft()
        }
        HStack {
            StatusChip.published()
            StatusChip.live()
        }
    }
    .padding()
    .background(Color.shBackgroundPrimary)
    .preferredColorScheme(.light)
}

#Preview("StatusChip Presets - Dark") {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            StatusChip.confirmed()
            StatusChip.arrived()
            StatusChip.completed()
        }
        HStack {
            StatusChip.unverified()
            StatusChip.lateCancel()
            StatusChip.cancelled()
        }
        HStack {
            StatusChip.noShow()
            StatusChip.missing()
            StatusChip.draft()
        }
        HStack {
            StatusChip.published()
            StatusChip.live()
        }
    }
    .padding()
    .background(Color.shBackgroundPrimary)
    .preferredColorScheme(.dark)
}
