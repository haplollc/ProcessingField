//
//  ProcessingField.swift
//  ProcessingField
//
//  A field of marks whose sizes describe one soft shape, drifting and folding
//  while something is being worked on. Drop it over anything as an overlay: it
//  draws only the field, never a background, and it takes no hits.
//
//  Self-contained: SwiftUI and nothing else.
//

import SwiftUI

/// A field of marks on a fixed square grid whose sizes describe one soft mass.
///
/// The mark centres never move. They sit on a fixed square grid and only each
/// mark's size, its ink, and (for ``ProcessingFieldStyle/lines``) its angle
/// change, which is what makes this read as one surface working rather than as
/// particles flying about. What the sizes describe is a single mass, not a
/// pattern: marks inside it stand at full size, marks outside fade to specks,
/// and the outline between them wobbles as the shape wanders, so it reads as
/// one form breathing rather than as bands crossing a grid.
///
/// Every mark in the grid is drawn on every frame. Outside the shape they are
/// small and quiet, never absent, so the lattice is always there and the shape
/// is read in the swelling of it.
///
/// It is one `Canvas` inside one `TimelineView`, with no view per mark, and the
/// timeline leaves the tree the moment ``isActive`` goes false. Under Reduce
/// Motion there is no timeline at all, only a still frame of the same field.
///
/// It fills whatever it is offered and draws no background, so it drops in as
/// an overlay in one line. The caller owns the clipping, and the
/// `processingFieldOverlay(_:in:)` modifier on `View` does both at once:
///
/// ```swift
/// card.processingFieldOverlay(
///     ProcessingField(style: .lines, isActive: isLoading, ink: .white),
///     in: RoundedRectangle(cornerRadius: 24, style: .continuous)
/// )
/// ```
///
/// Reach for this type directly when the field is the whole picture rather than
/// something laid over a card:
///
/// ```swift
/// ProcessingField(ink: .primary)
///     .frame(height: 320)
/// ```
///
/// It says nothing about how far along the work is, on purpose. There is no
/// bar, no ring and no accent colour, so nothing here can be misread as a
/// percentage. If you know the progress, show a progress view instead.
public struct ProcessingField: View {

    // MARK: Knobs

    /// Dots or lines. Same shape, same maths, different mark.
    public var style: ProcessingFieldStyle

    /// True while the work this describes is still running. False parks the
    /// field on a still frame and takes the timeline out of the tree, so an
    /// idle field costs nothing.
    public var isActive: Bool

    /// Distance between mark centres, in points. Adjusted a little to divide the
    /// field evenly, so the grid is never clipped down one edge.
    ///
    /// Keep the marks close enough together that a band the height of a few rows
    /// still reads as a surface: at a 20 point pitch a 104 point band is five
    /// rows of specks, which is a sprinkle rather than a field for a bloom to
    /// cross.
    public var pitch: CGFloat

    /// The one colour in the field. Monochrome by design: no accent, no bar, no
    /// ring, nothing that could be read as a percentage. White on a dark veil,
    /// near-black on paper, or `.primary` to follow the foreground.
    public var ink: Color

    /// How far the mass reaches, as a fraction of each axis. Measured off each
    /// axis separately, so the shape is a broad mass in a tall poster as readily
    /// as in a short band. Big enough by default to be the subject of the field
    /// rather than a spot floating in it; drop it to about 0.22 if you want the
    /// shape legible as one form inside a surround of specks.
    public var reach: Double

    /// The soft shoulder either side of the outline, in the same units as the
    /// outline: how far it takes a mark to go from a speck to full size. Larger
    /// is mistier, smaller is a harder edge.
    public var softness: Double

    /// Mark radius outside the shape, as a fraction of the pitch. The floor
    /// matters as much as the ceiling: it is what keeps every mark present.
    /// 0.085 at a 14 point pitch is a speck a little over a point across.
    public var minRadiusRatio: Double

    /// Mark radius inside the shape, as a fraction of the pitch. Keep it above
    /// ``minRadiusRatio``; below it the marks simply stop growing.
    public var maxRadiusRatio: Double

    /// Ink outside the shape. Well clear of zero, so a mark out there is quiet,
    /// never absent.
    public var minInk: Double

    /// Ink inside the shape. Set it below ``minInk`` and the mass reads as a
    /// hole punched in the field rather than a swelling of it, which is a real
    /// effect and not guarded against.
    public var maxInk: Double

    /// How fast the mass wanders about the frame. 1 is the tuned pace; 0 pins it
    /// in place and lets it fold without travelling. The two wandering periods
    /// underneath are set against each other so the path never retraces itself;
    /// this scales both at once.
    public var driftSpeed: Double

    /// How fast the outline folds and the mass breathes. 1 is the tuned pace; 0
    /// freezes the form and lets it only travel. The folds, their depths, the
    /// breath and the swell all move on periods that do not divide each other;
    /// this scales all of them at once.
    public var foldSpeed: Double

    /// ``ProcessingFieldStyle/lines`` only. Half the segment length, as a
    /// multiple of the radius the same mark would have as a dot. At the default
    /// knobs a segment inside the shape is a little shorter than the pitch, so
    /// the comb reads as one form without the segments crossing. Push it past
    /// about 2.9 and they will overlap, which is a flow-field look rather than a
    /// field of marks.
    public var lineLengthScale: Double

    /// ``ProcessingFieldStyle/lines`` only. Segment thickness, as a multiple of
    /// that same radius.
    public var lineWeightScale: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// Makes a field. Every knob is defaulted to the tuned value, so
    /// `ProcessingField()` is a usable field and you only name what you want to
    /// change.
    ///
    /// - Parameters:
    ///   - style: Dots or lines. Same shape either way.
    ///   - isActive: False parks the field on a still frame.
    ///   - pitch: Distance between mark centres, in points.
    ///   - ink: The one colour in the field.
    ///   - reach: How far the mass reaches, as a fraction of each axis.
    ///   - softness: The soft shoulder either side of the outline.
    ///   - minRadiusRatio: Mark radius outside the shape, over the pitch.
    ///   - maxRadiusRatio: Mark radius inside the shape, over the pitch.
    ///   - minInk: Ink outside the shape.
    ///   - maxInk: Ink inside the shape.
    ///   - driftSpeed: How fast the mass wanders. 0 pins it in place.
    ///   - foldSpeed: How fast the outline folds. 0 freezes the form.
    ///   - lineLengthScale: Half a segment's length, over the mark radius.
    ///   - lineWeightScale: A segment's thickness, over the mark radius.
    public init(
        style: ProcessingFieldStyle = .dots,
        isActive: Bool = true,
        pitch: CGFloat = 14,
        ink: Color = .primary,
        reach: Double = 0.40,
        softness: Double = 0.34,
        minRadiusRatio: Double = 0.085,
        maxRadiusRatio: Double = 0.19,
        minInk: Double = 0.30,
        maxInk: Double = 0.85,
        driftSpeed: Double = 1,
        foldSpeed: Double = 1,
        lineLengthScale: Double = 2.4,
        lineWeightScale: Double = 0.9
    ) {
        self.style = style
        self.isActive = isActive
        self.pitch = pitch
        self.ink = ink
        self.reach = reach
        self.softness = softness
        self.minRadiusRatio = minRadiusRatio
        self.maxRadiusRatio = maxRadiusRatio
        self.minInk = minInk
        self.maxInk = maxInk
        self.driftSpeed = driftSpeed
        self.foldSpeed = foldSpeed
        self.lineLengthScale = lineLengthScale
        self.lineWeightScale = lineWeightScale
    }

    // MARK: Body

    public var body: some View {
        Group {
            if isActive, !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    field(at: context.date.timeIntervalSinceReferenceDate)
                }
            } else {
                // Still: the shape resting in the middle at mid swell. The same
                // field, simply not moving. Reduce Motion and a finished job
                // land on the very same frame.
                field(at: nil)
            }
        }
        .allowsHitTesting(false)
        // A Canvas vends no accessibility elements to begin with, so this is
        // belt and braces; it applies to this subtree only and never touches the
        // label a caller wraps around the content underneath.
        .accessibilityHidden(true)
    }

    // MARK: Drawing

    /// One frame of the field. `nil` is the still frame.
    private func field(at time: TimeInterval?) -> some View {
        Canvas { context, size in
            guard size.width > 1, size.height > 1 else { return }

            // Everything that does not vary from mark to mark, worked out once.
            let frame = FieldFrame(
                size: size,
                time: time,
                pitch: pitch,
                reach: reach,
                softness: softness,
                minRadiusRatio: minRadiusRatio,
                maxRadiusRatio: maxRadiusRatio,
                minInk: minInk,
                maxInk: maxInk,
                driftSpeed: driftSpeed,
                foldSpeed: foldSpeed
            )

            let drawsLines = style == .lines
            let halfScale = max(0, lineLengthScale)
            let weightScale = max(0, lineWeightScale)

            for row in 0..<frame.rows {
                let y = frame.y(ofRow: row)
                // Half the position question answered once for the whole row.
                let ny = frame.normalisedY(y)

                for column in 0..<frame.columns {
                    let x = frame.x(ofColumn: column)
                    let nx = frame.normalisedX(x)

                    let level = frame.level(nx: nx, ny: ny)
                    let radius = frame.radius(atLevel: level)
                    let shade = GraphicsContext.Shading.color(
                        ink.opacity(frame.ink(atLevel: level))
                    )

                    if drawsLines {
                        // Tangent to the outline, so the segments comb around
                        // the mass and the whole grid reads as one form.
                        let along = frame.tangent(nx: nx, ny: ny)
                        let half = radius * halfScale
                        var segment = Path()
                        segment.move(to: CGPoint(x: x - along.x * half,
                                                 y: y - along.y * half))
                        segment.addLine(to: CGPoint(x: x + along.x * half,
                                                    y: y + along.y * half))
                        context.stroke(
                            segment,
                            with: shade,
                            style: StrokeStyle(
                                lineWidth: CGFloat(max(0.2, radius * weightScale)),
                                lineCap: .round
                            )
                        )
                    } else {
                        let box = CGRect(x: x - radius, y: y - radius,
                                         width: radius * 2, height: radius * 2)
                        context.fill(Path(ellipseIn: box), with: shade)
                    }
                }
            }
        }
    }
}

extension ProcessingField {
    /// `ProcessingField.Style` and ``ProcessingFieldStyle`` are the same type,
    /// so a caller can reach for either spelling.
    public typealias Style = ProcessingFieldStyle
}
