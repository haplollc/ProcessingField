//
//  Field.swift
//  ProcessingField
//
//  The shape, and the grid it is read on. Internal: this is the maths behind
//  the view, and none of it is part of the package's promise.
//

import CoreGraphics
import Foundation

/// The field at one moment: the grid the marks sit on, where the mass is, how
/// its outline happens to be folded just now, and how big and how dark a mark
/// is at either end of the ramp from outside the shape to inside it.
///
/// It exists so the drawing loop can stay a loop. Nothing in here varies from
/// mark to mark, so all of it is worked out once, before a single mark is
/// drawn; only ``level(nx:ny:)`` and ``tangent(nx:ny:)`` are asked per mark.
/// Keeping the tuned periods together also lets a reader check the thing that
/// matters about them: no two of them divide each other, which is what stops
/// the shape from ever folding the same way twice.
struct FieldFrame {

    // MARK: The grid

    /// Marks across. At least one, however little room there is.
    let columns: Int
    /// Marks down.
    let rows: Int
    /// Distance between mark centres, nudged off the requested pitch so a whole
    /// number of cells fills the width and nothing is half-drawn at an edge.
    let step: Double
    /// Top of the first row. The rows are centred in whatever height there is,
    /// so the leftover half-cell is split between top and bottom.
    let originY: Double

    // MARK: The mass

    private let centreX: Double
    private let centreY: Double
    /// One over the reach on each axis, so the per-mark maths multiplies
    /// instead of dividing. Measured off each axis separately, which is what
    /// lets the same shape be a broad mass in a tall poster and in a short band.
    private let invReachX: Double
    private let invReachY: Double
    /// How far the ramp is allowed to climb this frame: the slow breath over the
    /// whole field, so it swells as well as travels.
    private let swell: Double
    /// Where each of the three folds has turned to.
    private let fold1: Double
    private let fold2: Double
    private let fold3: Double
    /// How deep each fold is biting just now. Without these the shape only
    /// turns, holding one character while it slides about; with them the form
    /// itself changes as it travels, stretching one way, easing back, swelling
    /// another.
    private let depth1: Double
    private let depth2: Double
    private let depth3: Double
    /// Half the width of the soft shoulder either side of the outline, in
    /// outline units, and the full width of it.
    private let shoulder: Double
    private let shoulderSpan: Double

    // MARK: The weight of a mark

    /// Radius of a mark outside the shape, in points. The floor matters as much
    /// as the ceiling: it is what keeps every mark present.
    private let radiusFloor: Double
    /// How much more radius a mark gets at full level.
    private let radiusSpan: Double
    /// Ink outside the shape, and how much more a mark inside it gets.
    private let inkFloor: Double
    private let inkSpan: Double

    // MARK: Building a frame

    /// Works the whole frame out from the size on offer and the time of day.
    ///
    /// - Parameter time: Seconds, from any fixed origin. `nil` is the still
    ///   frame: the shape resting in the middle at mid swell, with the folds
    ///   unturned. Reduce Motion and a finished job both land on it.
    init(
        size: CGSize,
        time: TimeInterval?,
        pitch: CGFloat,
        reach: Double,
        softness: Double,
        minRadiusRatio: Double,
        maxRadiusRatio: Double,
        minInk: Double,
        maxInk: Double,
        driftSpeed: Double,
        foldSpeed: Double
    ) {
        let width = Double(size.width)
        let height = Double(size.height)

        // One step for both axes, nudged so a whole number of cells fills the
        // width, with the rows centred in whatever height there is. The grid
        // stays square and nothing is half-drawn at an edge.
        let wanted = max(1.0, Double(pitch))
        let columns = max(1, Int((width / wanted).rounded()))
        let step = width / Double(columns)
        self.columns = columns
        self.step = step
        self.rows = max(1, Int((height / step).rounded()))
        self.originY = (height - step * Double(self.rows)) / 2

        // The two clocks. They are separate so a caller can pin the mass in
        // place and let it fold, or freeze the form and let it only travel.
        let t = time ?? 0
        let driftT = t * max(0, driftSpeed)
        let foldT = t * max(0, foldSpeed)

        // Where the shape sits and how bright the field is as a whole.
        self.swell = time == nil
            ? Self.swellMid
            : Self.swellMid + Self.swellRange * sin(2 * .pi * foldT / 7.1)
        self.centreX = time == nil
            ? width / 2
            : width * (0.5 + 0.17 * sin(2 * .pi * driftT / 8.3))
        self.centreY = time == nil
            ? height / 2
            : height * (0.5 + 0.19 * sin(2 * .pi * driftT / 6.7 + 0.9))

        // The mass breathes as well as folds, so it is never the same size
        // twice running either.
        let breath = 1 + 0.10 * sin(2 * .pi * foldT / 6.1)
        let span = max(0.01, reach) * breath
        let reachX = max(0.5, width * span)
        let reachY = max(0.5, height * span)
        self.invReachX = 1 / reachX
        self.invReachY = 1 / reachY

        // The mark scale follows the pitch, so a denser grid draws
        // proportionally smaller marks and the field keeps the same weight
        // whatever size it is given.
        let radiusFloor = step * max(0, minRadiusRatio)
        self.radiusFloor = radiusFloor
        self.radiusSpan = max(0, step * maxRadiusRatio - radiusFloor)
        let inkFloor = min(max(minInk, 0), 1)
        self.inkFloor = inkFloor
        self.inkSpan = min(max(maxInk, 0), 1) - inkFloor

        // Three slow turns of the outline, at speeds that do not divide each
        // other, so the shape never folds the same way twice.
        self.fold1 = 0.34 * foldT
        self.fold2 = -0.22 * foldT
        self.fold3 = 0.16 * foldT
        // Each fold's depth has its own slow cycle too, on periods that again
        // share no common measure.
        self.depth1 = 0.10 + 0.08 * sin(2 * .pi * foldT / 5.9)
        self.depth2 = 0.06 + 0.05 * sin(2 * .pi * foldT / 4.3 + 1.7)
        self.depth3 = 0.05 + 0.04 * sin(2 * .pi * foldT / 7.7 + 0.4)

        self.shoulder = max(0.0001, softness)
        self.shoulderSpan = 2 * self.shoulder
    }

    // MARK: Walking the grid

    /// The x of the marks in a column, in view points.
    func x(ofColumn column: Int) -> Double {
        step * (Double(column) + 0.5)
    }

    /// The y of the marks in a row, in view points.
    func y(ofRow row: Int) -> Double {
        originY + step * (Double(row) + 0.5)
    }

    /// A point in view points, restated in units of the mass's reach, where 1 is
    /// roughly the outline. Split in two because the y half depends only on the
    /// row and the caller can hoist it out of the inner loop.
    func normalisedX(_ x: Double) -> Double { (x - centreX) * invReachX }
    func normalisedY(_ y: Double) -> Double { (y - centreY) * invReachY }

    // MARK: Asking about one mark

    /// How far inside the mass this mark is: 0 out in the surround, rising to
    /// this frame's swell at the heart of the shape.
    ///
    /// Every mark asks the same question. The outline is a circle bent by three
    /// slow folds, and the answer turns over across a soft shoulder either side
    /// of it, smoothed at both ends, so marks swell into the shape instead of
    /// popping on.
    func level(nx: Double, ny: Double) -> Double {
        let distance = (nx * nx + ny * ny).squareRoot()
        let angle = atan2(ny, nx)
        let outline = 1
            + depth1 * sin(3 * angle + fold1)
            + depth2 * sin(5 * angle + fold2)
            + depth3 * sin(2 * angle + fold3)
        let ramp = (outline + shoulder - distance) / shoulderSpan
        let edge = min(max(ramp, 0), 1)
        return edge * edge * (3 - 2 * edge) * swell
    }

    /// Radius of a mark at that level, in view points.
    func radius(atLevel level: Double) -> Double {
        radiusFloor + radiusSpan * level
    }

    /// Opacity of a mark at that level.
    func ink(atLevel level: Double) -> Double {
        inkFloor + inkSpan * level
    }

    /// The way around the mass at this mark: a unit vector square to the way out
    /// of the shape, which is what makes the `.lines` segments comb around it so
    /// the whole grid reads as one form.
    func tangent(nx: Double, ny: Double) -> (x: Double, y: Double) {
        let gx = nx * invReachX
        let gy = ny * invReachY
        let length = (gx * gx + gy * gy).squareRoot()
        guard length > 1e-9 else {
            // Dead centre has no direction out. Lie flat.
            return (1, 0)
        }
        return (-gy / length, gx / length)
    }

    // MARK: Tuning

    /// The slow swell over the whole field. The still frame parks at the middle
    /// of it, so a finished job looks like the moving field caught mid breath
    /// rather than like a different drawing.
    private static let swellMid: Double = 0.82
    private static let swellRange: Double = 0.18
}
