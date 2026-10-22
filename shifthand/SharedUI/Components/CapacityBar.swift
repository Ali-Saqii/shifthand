//
//  CapacityBar.swift
//  shifthand
//
//  Horizontal progress bar showing shift or event capacity fill.
//  Strictly compliant with Docs/UI_STANDARDS.md and Docs/COMPONENTS.md.
//

import SwiftUI

public struct CapacityBar: View {
    public let confirmed: Int
    public let capacity: Int
    public let tintColor: Color?

    public init(confirmed: Int, capacity: Int, tintColor: Color? = nil) {
        self.confirmed = confirmed
        self.capacity = capacity
        self.tintColor = tintColor
    }

    private var fillRatio: Double {
        guard capacity > 0 else { return 0.0 }
        let ratio = Double(confirmed) / Double(capacity)
        return min(max(ratio, 0.0), 1.0)
    }

    private var activeFillColor: Color {
        if let custom = tintColor {
            return custom
        }
        return confirmed >= capacity ? .shAccentAmber : .shPrimaryTeal
    }

    private var percentText: String {
        let percent = Int(fillRatio * 100)
        return "\(percent) percent"
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.shBorderDefault)
                    .frame(height: 8)

                // Fill Bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(activeFillColor)
                    .frame(width: geometry.size.width * fillRatio, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: fillRatio)
            }
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(confirmed) of \(capacity) seats filled")
        .accessibilityValue(percentText)
    }
}

// MARK: - Previews (Light and Dark)
#Preview("CapacityBar - Light") {
    VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 6) {
            Text("Partial Fill (4/10)")
                .font(.caption)
                .foregroundStyle(Color.shTextSecondary)
            CapacityBar(confirmed: 4, capacity: 10)
        }

        VStack(alignment: .leading, spacing: 6) {
            Text("Full Capacity (10/10)")
                .font(.caption)
                .foregroundStyle(Color.shTextSecondary)
            CapacityBar(confirmed: 10, capacity: 10)
        }

        VStack(alignment: .leading, spacing: 6) {
            Text("Over Capacity (12/10)")
                .font(.caption)
                .foregroundStyle(Color.shTextSecondary)
            CapacityBar(confirmed: 12, capacity: 10)
        }

        VStack(alignment: .leading, spacing: 6) {
            Text("Empty (0/10)")
                .font(.caption)
                .foregroundStyle(Color.shTextSecondary)
            CapacityBar(confirmed: 0, capacity: 10)
        }
    }
    .padding()
    .background(Color.shBackgroundCard)
    .preferredColorScheme(.light)
}

#Preview("CapacityBar - Dark") {
    VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 6) {
            Text("Partial Fill (4/10)")
                .font(.caption)
                .foregroundStyle(Color.shTextSecondary)
            CapacityBar(confirmed: 4, capacity: 10)
        }

        VStack(alignment: .leading, spacing: 6) {
            Text("Full Capacity (10/10)")
                .font(.caption)
                .foregroundStyle(Color.shTextSecondary)
            CapacityBar(confirmed: 10, capacity: 10)
        }
    }
    .padding()
    .background(Color.shBackgroundCard)
    .preferredColorScheme(.dark)
}
