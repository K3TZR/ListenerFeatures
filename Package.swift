// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Listener",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
  ],

  products: [
    .library(name: "Listener", targets: ["Listener"]),
  ],

  dependencies: [
    .package(url: "https://github.com/auth0/JWTDecode.swift", from: "2.6.0"),
    .package(url: "https://github.com/K3TZR/SharedComponents.git", from: "1.2.1"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.5.0"),
    .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.5"),
  ],

  targets: [
    // --------------- Modules ---------------
    // Listener
    .target(name: "Listener",dependencies: [
      .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
      .product(name: "JWTDecode", package: "JWTDecode.swift"),
      .product(name: "Shared", package: "SharedComponents"),
    ]),

    // ---------------- Tests ----------------
    // ListenerTests
    .testTarget(name: "ListenerTests",dependencies: ["Listener"]),
  ]
)
