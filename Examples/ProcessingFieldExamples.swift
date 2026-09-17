//
//  ProcessingFieldExamples.swift
//
//  EXAMPLE CODE. This file is not part of the ProcessingField library and the
//  package does not compile it: the Examples folder sits outside Sources on
//  purpose, so nothing here can quietly become API you have to support. Copy a
//  piece into your own app and change it there.
//
//  The #Preview blocks want Xcode 15 or newer. Delete them if you are on an
//  older one; nothing else in the file needs it.
//

import ProcessingField
import SwiftUI

// MARK: - The common case: a card being filled in

/// A card whose contents are still being worked out. This is what most people
/// want: the field laid over something, clipped to that something's shape.
///
/// The field is over the card rather than behind its text, so the words stay
/// the brightest thing on it. The ink is white because the card is dark; on a
/// pale card use `.primary` or a near-black.
struct SummaryCard: View {

    var isWorking: Bool
    var summary: String

    private let corner = RoundedRectangle(cornerRadius: 24, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.55))

            Text(isWorking ? "Reading it through" : summary)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.13, blue: 0.20),
                         Color(red: 0.05, green: 0.06, blue: 0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(corner)
        // One line for the whole job, and it is passed the same shape the card
        // is clipped to, since the modifier clips only the field and leaves the
        // card alone. `isActive` is the only thing that has to change when the
        // work finishes: false parks the field on a still frame and takes the
        // timeline out of the view tree, so an idle card is free.
        .processingFieldOverlay(
            ProcessingField(style: .lines, isActive: isWorking, ink: .white),
            in: corner
        )
    }
}

// MARK: - The field as the whole picture

/// No card, no veil, nothing behind it. The component draws no background of
/// its own, which is what makes this possible: it is an overlay, and here the
/// overlay is all there is.
///
/// `reach` is pulled in from the default 0.40 because at full page size the
/// tuned reach fills the frame and every mark sits at full size, which reads as
/// a flat grid. Tighter, the shape is legible as one form inside a surround of
/// specks.
struct WorkingScreen: View {

    var body: some View {
        VStack(spacing: 18) {
            ProcessingField(ink: .primary, reach: 0.22)
                .frame(height: 320)

            Text("Working on it")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Both marks, side by side

/// The two styles describe the same shape with the same maths. Only the mark
/// changes, so picking one is a question of texture.
struct StyleComparison: View {

    private let corner = RoundedRectangle(cornerRadius: 20, style: .continuous)

    var body: some View {
        HStack(spacing: 14) {
            ForEach(ProcessingFieldStyle.allCases) { style in
                Color(white: 0.95)
                    .clipShape(corner)
                    .processingFieldOverlay(
                        ProcessingField(style: style, pitch: 11, ink: Color(white: 0.12)),
                        in: corner
                    )
                    .overlay(alignment: .bottomLeading) {
                        Text(style.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color(white: 0.35))
                            .padding(10)
                    }
            }
        }
        .frame(height: 140)
    }
}

// MARK: - Previews

#Preview("Card") {
    VStack(spacing: 20) {
        SummaryCard(isWorking: true, summary: "Four points, none of them new.")
        SummaryCard(isWorking: false, summary: "Four points, none of them new.")
    }
    .padding(24)
}

#Preview("Whole picture") {
    WorkingScreen()
}

#Preview("Both marks") {
    StyleComparison()
        .padding(24)
}
