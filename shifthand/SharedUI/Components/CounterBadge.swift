//
//  CounterBadge.swift
//  shifthand
//
//  Metric tile displaying live day attendance figures (Expected, Arrived, Missing).
//  Designed for high outdoor contrast and strict VoiceOver accessibility compliance.
//

import SwiftUI

public struct CounterBadge: View {
    public let count: Int
    public let label: String
    public let tint: Color
    public let accessibilityDescription: String?

    public init(
        count: Int,
        label: String,
        tint: Color,
        accessibilityDescription: String? = nil
    ) {
        self.count = count
        self.label = label
        self.tint = tint
        self.accessibilityDescription = accessibilityDescription
    }

    private var voiceOverLabel: String {
        accessibilityDescription ?? "\(label): \(count) volunteers"
    }

    public var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .contentTransition(.numericText())

            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.shTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.shBackgroundCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.shBorderDefault, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOverLabel)
    }
}

// MARK: - Previews (Light and Dark)
#Preview("CounterBadge Row - Light") {
    HStack(spacing: 12) {
        CounterBadge(
            count: 12,
            label: "Expected",
            tint: .shPrimaryTeal,
            accessibilityDescription: "Expected: 12 volunteers"
        )
        CounterBadge(
            count: 7,
            label: "Arrived",
            tint: .shStatusGreen,
            accessibilityDescription: "Arrived 7 of 12 volunteers"
        )
        CounterBadge(
            count: 5,
            label: "Missing",
            tint: .shStatusRed,
            accessibilityDescription: "Missing 5 of 12 volunteers"
        )
    }
    .padding()
    .background(Color.shBackgroundPrimary)
    .preferredColorScheme(.light)
}

#Preview("CounterBadge Row - Dark") {
    HStack(spacing: 12) {
        CounterBadge(
            count: 12,
            label: "Expected",
            tint: .shPrimaryTeal
        )
        CounterBadge(
            count: 7,
            label: "Arrived",
            tint: .shStatusGreen,
            accessibilityDescription: "Arrived 7 of 12"
        )
        CounterBadge(
            count: 5,
            label: "Missing",
            tint: .shStatusRed
        )
    }
    .padding()
    .background(Color.shBackgroundPrimary)
    .preferredColorScheme(.dark)
}
