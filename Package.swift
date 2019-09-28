// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataTables",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "DataTables",
            targets: ["DataTables"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // 💧 A server-side Swift web framework.,
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "3.0.0")),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", .upToNextMajor(from: "3.0.0"))

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "DataTables",
            dependencies: ["Vapor", "FluentSQLite"]),
        .testTarget(
            name: "DataTablesTests",
            dependencies: ["DataTables"]),
    ]
)
