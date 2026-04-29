import Foundation

struct ObjectMeasurement {
    let width: Float   // cm (largest horizontal dimension)
    let length: Float  // cm (second horizontal dimension)
    let height: Float  // cm (vertical dimension)

    var girth: Float { width + length + height }

    var sortedDimensions: (Float, Float, Float) {
        let sorted = [width, length, height].sorted(by: >)
        return (sorted[0], sorted[1], sorted[2])
    }

    var formattedDescription: String {
        String(format: "%.1f × %.1f × %.1f cm", width, length, height)
    }
}
