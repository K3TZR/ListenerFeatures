// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ListenerFeatures",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
  ],

  products: [
    .library(name: "ListenerFeature", targets: ["ListenerFeature"]),
    .library(name: "LoginFeature", targets: ["LoginFeature"]),
  ],

  dependencies: [
    .package(url: "https://github.com/auth0/JWTDecode.swift", from: "2.6.0"),
    .package(url: "https://github.com/K3TZR/SharedFeatures.git", from: "1.2.1"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.42.0"),
    .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.5"),
  ],

  targets: [
    // --------------- Modules ---------------
    // ListenerFeature
    .target(name: "ListenerFeature",dependencies: [
      .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      .product(name: "JWTDecode", package: "JWTDecode.swift"),
      .product(name: "Shared", package: "SharedFeatures"),
      "LoginFeature",
    ]),

    // LoginFeature
    .target(name: "LoginFeature",dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
    ]),

    // ---------------- Tests ----------------
    // ListenerFeaturesTests
    .testTarget(name: "ListenerFeatureTests",dependencies: ["ListenerFeature"]),
  ]
)
