//
//  ProcessingFieldPlayground.swift
//
//  EXAMPLE CODE. This file is not part of the ProcessingField library and the
//  package does not compile it. It is here to be dropped into a scratch app so
//  you can feel what each knob does before you pick numbers for your own.
//
//  The field on the page's own ground, so the only thing on screen is the marks
//  themselves. No photo, no veil, no card edge. The component draws no
//  background of its own, which is what makes that possible.
//
//  Underneath, every knob the field exposes. The still frame is forced with a
//  toggle, so both states can be seen without going to Settings.
//
//  The #Preview block wants Xcode 15 or newer, and the sliders want a platform
//  that has them, so this is an iOS, macOS or visionOS page rather than a tvOS
//  or watchOS one.
//

import ProcessingField
import SwiftUI

struct ProcessingFieldPlayground: View {

    // MARK: - State

    @State private var style: ProcessingFieldStyle = .dots
    @State private var isRunning = true
    @State private var forceStill = false

    @State private var pitch: Double = Defaults.pitch
    @State private var reach: Double = Defaults.reach
    @State private var softness: Double = Defaults.softness
    @State private var radiusFloor: Double = Defaults.radiusFloor
    @State private var radiusCeiling: Double = Defaults.radiusCeiling
    @State private var inkFloor: Double = Defaults.inkFloor
    @State private var inkCeiling: Double = Defaults.inkCeiling
    @State private var driftSpeed: Double = Defaults.driftSpeed
    @State private var foldSpeed: Double = Defaults.foldSpeed

    /// What the system itself asks for. A viewer who has already turned Reduce
    /// Motion on keeps the still field whatever the toggle here says: this page
    /// can force the still frame ON, never off.
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private var showsStill: Bool { forceStill || systemReduceMotion }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            hero
                .padding(.horizontal, 20)
                .padding(.top, 12)

            caption
                .padding(.horizontal, 32)
                .padding(.top, 14)
                .padding(.bottom, 4)

            controls
        }
    }

    // MARK: - The hero

    /// The field on the page's own ground. Nothing is drawn behind it and
    /// nothing around it, so the marks are the whole picture. The ink follows
    /// the foreground colour, so it is near-black on paper and near-white in the
    /// dark.
    private var hero: some View {
        ProcessingField(
            style: style,
            isActive: isRunning && !showsStill,
            pitch: CGFloat(pitch),
            ink: .primary,
            reach: reach,
            softness: softness,
            minRadiusRatio: radiusFloor,
            maxRadiusRatio: radiusCeiling,
            minInk: inkFloor,
            maxInk: inkCeiling,
            driftSpeed: driftSpeed,
            foldSpeed: foldSpeed
        )
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }

    private var caption: some View {
        Text(captionText)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.2), value: captionText)
    }

    private var captionText: String {
        if showsStill {
            return "Still frame. The same field, simply not moving."
        }
        if !isRunning {
            return "Parked. The timeline leaves the tree entirely."
        }
        return "The mark centres never move. Only their size and their ink do."
    }

    // MARK: - The controls

    private var controls: some View {
        Form {
            Section("Mark") {
                Picker("Style", selection: $style) {
                    ForEach(ProcessingFieldStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("State") {
                Toggle("Running", isOn: $isRunning)
                Toggle("Still frame (Reduce Motion)", isOn: $forceStill)
                    .disabled(systemReduceMotion)

                if systemReduceMotion {
                    Text("Reduce Motion is on for this device, so the field is already still.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Grid") {
                knob("Pitch", $pitch, 6...32, format: "%.0f", suffix: " pt")
                knob("Reach", $reach, 0.12...0.70)
                knob("Softness", $softness, 0.04...0.80)
                knob("Drift speed", $driftSpeed, 0...3, suffix: "x")
                knob("Fold speed", $foldSpeed, 0...3, suffix: "x")
            }

            Section("Weight of a mark") {
                knob("Radius floor", clamped($radiusFloor, below: $radiusCeiling),
                     0...0.20, format: "%.3f")
                knob("Radius ceiling", clamped($radiusCeiling, above: $radiusFloor),
                     0.02...0.45, format: "%.3f")
                knob("Ink floor", clamped($inkFloor, below: $inkCeiling), 0...0.70)
                knob("Ink ceiling", clamped($inkCeiling, above: $inkFloor), 0.05...1)
            }

            Section {
                Button("Reset") {
                    withAnimation(.easeInOut(duration: 0.2)) { reset() }
                }
            }
        }
    }

    // MARK: - Pieces

    /// One labelled slider. The value sits on the label's line rather than in a
    /// column beside it, so the slider keeps the full width at phone size.
    private func knob(_ label: String,
                      _ value: Binding<Double>,
                      _ range: ClosedRange<Double>,
                      format: String = "%.2f",
                      suffix: String = "") -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value.wrappedValue) + suffix)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }

    /// A floor that cannot be dragged past its ceiling, and the reverse. The
    /// thumb stops rather than shoving the other knob along, so a pair stays
    /// where you left it.
    private func clamped(_ value: Binding<Double>,
                         below ceiling: Binding<Double>) -> Binding<Double> {
        Binding(get: { value.wrappedValue },
                set: { value.wrappedValue = min($0, ceiling.wrappedValue - 0.005) })
    }

    private func clamped(_ value: Binding<Double>,
                         above floor: Binding<Double>) -> Binding<Double> {
        Binding(get: { value.wrappedValue },
                set: { value.wrappedValue = max($0, floor.wrappedValue + 0.005) })
    }

    private func reset() {
        style = .dots
        isRunning = true
        forceStill = false
        pitch = Defaults.pitch
        reach = Defaults.reach
        softness = Defaults.softness
        radiusFloor = Defaults.radiusFloor
        radiusCeiling = Defaults.radiusCeiling
        inkFloor = Defaults.inkFloor
        inkCeiling = Defaults.inkCeiling
        driftSpeed = Defaults.driftSpeed
        foldSpeed = Defaults.foldSpeed
    }

    /// Where the sliders start, and where Reset goes back to. These mirror the
    /// component's own resting values apart from reach: at 0.40 the mass spans a
    /// hero this size almost completely, so every mark sits at full size and the
    /// field reads as a flat grid. The page opens a little tighter, where the
    /// shape is legible as one form inside a surround of specks.
    private enum Defaults {
        static let pitch: Double = 14
        static let reach: Double = 0.22
        static let softness: Double = 0.34
        static let radiusFloor: Double = 0.085
        static let radiusCeiling: Double = 0.19
        static let inkFloor: Double = 0.30
        static let inkCeiling: Double = 0.85
        static let driftSpeed: Double = 1
        static let foldSpeed: Double = 1
    }
}

#Preview {
    ProcessingFieldPlayground()
}
