// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TypingPet",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TypingPet", targets: ["TypingPet"])
    ],
    targets: [
        .executableTarget(name: "TypingPet")
    ],
    swiftLanguageModes: [.v5]
)
