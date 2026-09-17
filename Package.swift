// swift-tools-version: 5.9
//
//  Package.swift
//  ProcessingField
//
//  The floor is set by what the component actually uses. Canvas and
//  TimelineView both arrived in iOS 15 / macOS 12 / tvOS 15 / watchOS 8, and
//  nothing else in the target reaches past them, so that is where the package
//  stops rather than somewhere more convenient. macOS is here so `swift build`
//  works on a contributor's machine without a simulator.
//

import PackageDescription

let package = Package(
    name: "ProcessingField",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "ProcessingField",
            targets: ["ProcessingField"]
        )
    ],
    targets: [
        .target(name: "ProcessingField")
    ]
)
