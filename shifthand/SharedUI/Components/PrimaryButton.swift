//
//  PrimaryButton.swift
//  shifthand
//
//  Standard high-emphasis primary button with loading spinner state.
//  Strictly compliant with Docs/UI_STANDARDS.md and Docs/COMPONENTS.md.
//

import SwiftUI

public struct PrimaryButton: View {
    public let title: String
    public let isLoading: Bool
    public let isEnabled: Bool
    public let role: ButtonRole?
    public let action: () -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.role = role
        self.action = action
    }

    private var buttonBackgroundColor: Color {
        if role == .destructive {
            return .shStatusRed
        }
        return .shPrimaryTeal
    }

    public var body: some View {
        Button(role: role, action: {
            guard isEnabled && !isLoading else { return }
            action()
        }) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: SHMetrics.buttonCornerRadius)
                    .fill(buttonBackgroundColor)
                    .opacity(isEnabled ? 1.0 : 0.45)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isLoading ? "In progress" : (isEnabled ? "" : "Disabled"))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews (Light and Dark)
//#Preview() {
//    VStack(spacing: 16) {
//        PrimaryButton(title: "Sign In", isLoading: false, isEnabled: true, action: {})
//        PrimaryButton(title: "Signing In...", isLoading: true, isEnabled: true, action: {})
//        PrimaryButton(title: "Save Changes", isLoading: false, isEnabled: false, action: {})
//        PrimaryButton(title: "Delete Account", isLoading: false, isEnabled: true, role: .destructive, action: {})
//    }
//    .padding()
//    .background(Color.shBackgroundPrimary)
//    .preferredColorScheme(.light)
//}
//
//#Preview() {
//    VStack(spacing: 16) {
//        PrimaryButton(title: "Sign In", isLoading: false, isEnabled: true, action: {})
//        PrimaryButton(title: "Signing In...", isLoading: true, isEnabled: true, action: {})
//        PrimaryButton(title: "Delete Account", isLoading: false, isEnabled: true, role: .destructive, action: {})
//    }
//    .padding()
//    .background(Color.shBackgroundPrimary)
//    .preferredColorScheme(.dark)
//}
