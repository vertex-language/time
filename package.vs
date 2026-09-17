// The 'time' package: durations, timestamps, a monotonic clock, and sleeping.
import PackageDescription

let package = Package(
    name: "time",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "time", targets: ["time"]),
        .executable(name: "stopwatch", targets: ["stopwatch"]),
        .executable(name: "check", targets: ["check"]),
    ],
    targets: [
        // The operating system's clocks, as a C ABI.
        .target(
            name: "cclock",
            path: "time/cclock",
            publicHeadersPath: "include"
        ),
        // The package: Vertex types over cclock.
        .target(
            name: "time",
            dependencies: ["cclock"],
            path: "time",
            exclude: ["cclock"]
        ),
        // Times a few sleeps, blocking and not.
        .executableTarget(
            name: "stopwatch",
            dependencies: ["time"],
            path: "examples/stopwatch"
        ),
        // The package checked against itself.
        .executableTarget(
            name: "check",
            dependencies: ["time"],
            path: "tests/check"
        ),
    ]
)
