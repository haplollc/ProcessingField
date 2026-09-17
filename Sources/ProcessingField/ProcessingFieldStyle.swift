//
//  ProcessingFieldStyle.swift
//  ProcessingField
//

import Foundation

/// Which mark the field is drawn with.
///
/// Both variants describe the SAME shape with the same field maths; only the
/// mark changes. Picking one is a question of texture, not of meaning: neither
/// style says anything the other does not.
public enum ProcessingFieldStyle: String, CaseIterable, Identifiable, Sendable {

    /// Circles that swell inside the shape and shrink to specks outside it.
    case dots

    /// Short segments that comb around the outline, tangent to it, growing long
    /// and thick inside the shape and staying short and quiet outside.
    case lines

    /// The raw value, so the style drops straight into a `ForEach` or a
    /// `Picker` without a wrapper.
    public var id: String { rawValue }

    /// A short name for the style, for when a picker needs one. It is deliberately
    /// not localized: it is a convenience for demos and debug UI, and an app
    /// showing this to real users should supply its own wording.
    public var label: String {
        switch self {
        case .dots: return "Dots"
        case .lines: return "Lines"
        }
    }
}
