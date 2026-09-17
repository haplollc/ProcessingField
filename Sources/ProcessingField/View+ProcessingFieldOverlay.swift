//
//  View+ProcessingFieldOverlay.swift
//  ProcessingField
//

import SwiftUI

extension View {

    /// Lays a ``ProcessingField`` over this view and clips the field to a shape.
    ///
    /// This is the short spelling of the thing nearly everybody does first.
    /// ``ProcessingField`` draws no background and fills whatever it is given,
    /// so on a rounded card the raw view would spill marks into the corners; the
    /// answer is always an overlay plus a clip, and this does both:
    ///
    /// ```swift
    /// card.processingFieldOverlay(
    ///     ProcessingField(style: .lines, isActive: isLoading, ink: .white),
    ///     in: RoundedRectangle(cornerRadius: 24, style: .continuous)
    /// )
    /// ```
    ///
    /// Only the field is clipped. This view is handed back exactly as it was, so
    /// adding the overlay cannot change how the content underneath is drawn or
    /// laid out, and it is safe to add to something already clipped by its own
    /// container.
    ///
    /// The field goes on taking no hits and vending no accessibility elements,
    /// so a button underneath stays a button.
    ///
    /// - Parameters:
    ///   - field: The field to draw. Defaults to `ProcessingField()`, which is
    ///     the tuned dots at full strength; pass one you have configured to
    ///     change the style, the ink, or whether it is running.
    ///   - shape: What to clip the field to. Match it to the shape of whatever
    ///     is underneath. The default `Rectangle()` clips to the view's own
    ///     bounds, which is what a square-cornered card wants.
    /// - Returns: This view, with the field over it.
    public func processingFieldOverlay<ClipShape: Shape>(
        _ field: ProcessingField = ProcessingField(),
        in shape: ClipShape = Rectangle()
    ) -> some View {
        overlay {
            field.clipShape(shape)
        }
    }
}
