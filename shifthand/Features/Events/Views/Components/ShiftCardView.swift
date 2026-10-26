//
//  ShiftCardView.swift
//  shifthand
//
//  Card displaying shift role, time range, capacity bar, and assigned shift lead.
//  Conforms strictly to Docs/UI_STANDARDS.md and Docs/SCREENS.md.
//

import SwiftUI

public struct ShiftCardView: View {
    public let shift: Shift
    public var onSelect: (() -> Void)?

    public init(shift: Shift, onSelect: (() -> Void)? = nil) {
        self.shift = shift
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: { onSelect?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // Role Label & Time Range
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shift.roleLabel)
                            .font(.headline)
                            .foregroundStyle(Color.shTextPrimary)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundStyle(Color.shTextSecondary)

                            Text(formattedTimeRange)
                                .font(.subheadline)
                                .foregroundStyle(Color.shTextSecondary)
                        }
                    }

                    Spacer()

                    // Lead status tag
                    if let leadName = shift.leadUserName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                            Text(leadName)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color.shAccentAmber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.shAccentAmber.opacity(0.12))
                        .clipShape(Capsule())
                    } else {
                        Text("No Lead")
                            .font(.caption)
                            .foregroundStyle(Color.shTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.shBorderDefault.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }

                // Capacity & Fill Progress
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Volunteers")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.shTextSecondary)

                        Spacer()

                        Text("\(shift.confirmedCount)/\(shift.capacity) filled")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(shift.isFull ? Color.shAccentAmber : Color.shTextPrimary)
                    }

                    CapacityBar(
                        confirmed: shift.confirmedCount,
                        capacity: shift.capacity
                    )
                }

                // Notes if present
                if let notes = shift.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.footnote)
                        .foregroundStyle(Color.shTextSecondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .frame(minHeight: SHMetrics.minTouchTarget)
            .background(Color.shBackgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                    .stroke(Color.shBorderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(shift.roleLabel), \(formattedTimeRange), \(shift.confirmedCount) of \(shift.capacity) volunteers confirmed, Lead: \(shift.leadUserName ?? "Unassigned")")
    }

    private var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: shift.startsAtUtc)) - \(formatter.string(from: shift.endsAtUtc))"
    }
}

// MARK: - Previews
#Preview("ShiftCardView") {
    VStack(spacing: 12) {
        ShiftCardView(
            shift: Shift(
                id: "1",
                roleLabel: "Morning Sorter & Packer",
                startsAtUtc: Date(),
                endsAtUtc: Date().addingTimeInterval(14400),
                capacity: 10,
                confirmedCount: 8,
                leadUserName: "Tariq Vance",
                notes: "Assemble at Hall B staging dock."
            )
        )
        ShiftCardView(
            shift: Shift(
                id: "2",
                roleLabel: "Registration Desk",
                startsAtUtc: Date(),
                endsAtUtc: Date().addingTimeInterval(7200),
                capacity: 6,
                confirmedCount: 6,
                leadUserName: nil
            )
        )
    }
    .padding()
    .background(Color.shBackgroundPrimary)
}
