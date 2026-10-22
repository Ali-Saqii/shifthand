//
//  LoadingView.swift
//  shifthand
//
//  Centered, unobtrusive activity spinner with optional progress message.
//  Strictly compliant with Docs/UI_STANDARDS.md and Docs/COMPONENTS.md.
//

import SwiftUI

public struct LoadingView: View {
    public let message: String?

    public init(message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.shPrimaryTeal)
                .scaleEffect(1.2)

            if let message = message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.shTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
    }
}

// MARK: - Previews (Light and Dark)
#Preview("LoadingView - Light") {
    LoadingView(message: "Loading today's shifts...")
        .background(Color.shBackgroundPrimary)
        .preferredColorScheme(.light)
}

#Preview("LoadingView - Dark") {
    LoadingView(message: "Authenticating...")
        .background(Color.shBackgroundPrimary)
        .preferredColorScheme(.dark)
}
