//
//  EventCardView.swift
//  shifthand
//
//  Reusable card displaying event summary, status chip, and capacity bar.
//  Conforms strictly to Docs/UI_STANDARDS.md and Docs/COMPONENTS.md.
//

import SwiftUI

public struct EventCardView: View {
    public let event: Event
    public var onSelect: (() -> Void)?

    public init(event: Event, onSelect: (() -> Void)? = nil) {
        self.event = event
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: { onSelect?() }) {
            VStack(alignment: .leading, spacing: 14) {
                // Top row: Title & Status Chip
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .foregroundStyle(Color.shTextPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundStyle(Color.shPrimaryTeal)

                            Text(event.venue)
                                .font(.subheadline)
                                .foregroundStyle(Color.shTextSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    StatusChip(
                        title: event.status.displayName,
                        systemImage: event.status.iconName,
                        style: event.status.chipStyle
                    )
                }

                // Date & Time Row
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.shTextSecondary)

                    Text(formattedDateTimeRange)
                        .font(.footnote)
                        .foregroundStyle(Color.shTextSecondary)
                }

                // Capacity Bar (only shown if capacity > 0)
                if event.totalCapacity > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Volunteers")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.shTextSecondary)

                            Spacer()

                            Text("\(event.totalConfirmed)/\(event.totalCapacity) seats")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(event.isFull ? Color.shAccentAmber : Color.shTextPrimary)
                        }

                        CapacityBar(
                            confirmed: event.totalConfirmed,
                            capacity: event.totalCapacity
                        )
                    }
                    .padding(.top, 2)
                }
            }
            .padding(16)
            .frame(minHeight: SHMetrics.minTouchTarget)
            .background(Color.shBackgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: SHCornerRadius.large)
                    .stroke(Color.shBorderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.title), at \(event.venue), on \(formattedDateTimeRange), Status: \(event.status.displayName), \(event.totalCapacity > 0 ? "\(event.totalConfirmed) of \(event.totalCapacity) seats filled" : "")")
    }

    private var formattedDateTimeRange: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, d MMM"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let datePart = dateFormatter.string(from: event.startsAt)
        let startTime = timeFormatter.string(from: event.startsAt)
        let endTime = timeFormatter.string(from: event.endsAt)

        return "\(datePart) • \(startTime) - \(endTime)"
    }
}

// MARK: - Previews (Light and Dark)
#Preview("EventCard - Published") {
    EventCardView(
        event: Event(
            id: "1",
            title: "Community Food Drive & Packing",
            venue: "Civic Centre, Hall B",
            startsAt: Date(),
            endsAt: Date().addingTimeInterval(14400),
            status: .published,
            publicSlug: "cfd",
            totalConfirmed: 14,
            totalCapacity: 20
        )
    )
    .padding()
    .background(Color.shBackgroundPrimary)
}

#Preview("EventCard - Draft") {
    EventCardView(
        event: Event(
            id: "2",
            title: "Winter Relief Strategy",
            venue: "St. Jude Centre",
            startsAt: Date().addingTimeInterval(86400),
            endsAt: Date().addingTimeInterval(90000),
            status: .draft,
            publicSlug: "winter",
            totalConfirmed: 0,
            totalCapacity: 0
        )
    )
    .padding()
    .background(Color.shBackgroundPrimary)
}
