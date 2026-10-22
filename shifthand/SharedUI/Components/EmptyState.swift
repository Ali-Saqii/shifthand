//
//  EmptyState.swift
//  shifthand
//
//  Standard placeholder displayed when lists or screens contain no items.
//  Strictly compliant with Docs/UI_STANDARDS.md and Docs/COMPONENTS.md.
//

import SwiftUI

public struct EmptyState: View {
    public let systemImage: String
    public let title: String
    public let message: String
    public let actionTitle: String?
    public let action: (() -> Void)?

    public init(
        systemImage: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Color.shPrimaryTeal)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.shTextPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.shTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.shPrimaryTeal)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius)
                                .fill(Color.shPrimaryTeal.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius)
                                .stroke(Color.shPrimaryTeal.opacity(0.24), lineWidth: 1)
                        )
                        .frame(minHeight: SHMetrics.minTouchTarget)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews (Light and Dark)
#Preview("EmptyState - Light") {
    EmptyState(
        systemImage: "calendar.badge.clock",
        title: "No Upcoming Events",
        message: "You haven't scheduled any events yet. Create an event to get started.",
        actionTitle: "Create Event",
        action: {}
    )
    .background(Color.shBackgroundPrimary)
    .preferredColorScheme(.light)
}

#Preview("EmptyState - Dark") {
    EmptyState(
        systemImage: "person.2.slash",
        title: "No Shifts Assigned Today",
        message: "You have no volunteer shifts assigned to lead today.",
        actionTitle: nil,
        action: nil
    )
    .background(Color.shBackgroundPrimary)
    .preferredColorScheme(.dark)
}
