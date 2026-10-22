//
//  ErrorBanner.swift
//  shifthand
//
//  Standard actionable error presentation banner.
//  Strictly compliant with Docs/UI_STANDARDS.md and Docs/COMPONENTS.md.
//

import SwiftUI

public struct ErrorBanner: View {
    public let message: String
    public let retryAction: (() -> Void)?
    public let dismissAction: (() -> Void)?

    public init(
        message: String,
        retryAction: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.retryAction = retryAction
        self.dismissAction = dismissAction
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.shStatusRed)
                .accessibilityHidden(true)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.shTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Text("Retry")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.shStatusRed)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(minHeight: SHMetrics.minTouchTarget)
                }
                .buttonStyle(.plain)
            }

            if let dismissAction = dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.shTextSecondary)
                        .frame(width: SHMetrics.minTouchTarget, height: SHMetrics.minTouchTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss error")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius)
                .fill(Color.shStatusRed.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius)
                .stroke(Color.shStatusRed.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error: \(message)")
    }
}

// MARK: - Previews (Light and Dark)
#Preview("ErrorBanner - Light") {
    VStack(spacing: 16) {
        ErrorBanner(
            message: "Unable to load today's shifts. Check your network.",
            retryAction: {},
            dismissAction: {}
        )

        ErrorBanner(
            message: "This shift has reached maximum volunteer capacity.",
            retryAction: nil,
            dismissAction: {}
        )
    }
    .padding()
    .background(Color.shBackgroundPrimary)
    .preferredColorScheme(.light)
}

#Preview("ErrorBanner - Dark") {
    VStack(spacing: 16) {
        ErrorBanner(
            message: "Unable to connect to server.",
            retryAction: {},
            dismissAction: {}
        )
    }
    .padding()
    .background(Color.shBackgroundPrimary)
    .preferredColorScheme(.dark)
}
