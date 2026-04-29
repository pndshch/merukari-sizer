import Foundation
import Combine
import simd

enum MeasurementPhase: Equatable {
    case detectingPlane
    case tappingFirstCorner
    case tappingSecondCorner
    case tappingHeight
    case complete
}

@MainActor
final class MeasurementViewModel: ObservableObject {
    @Published var phase: MeasurementPhase = .detectingPlane
    @Published var measurement: ObjectMeasurement?

    private(set) var floorY: Float = 0
    private(set) var firstCorner: SIMD3<Float>?
    private(set) var secondCorner: SIMD3<Float>?

    var instructionText: String {
        switch phase {
        case .detectingPlane:
            return "物体を平らな面に置いて\nカメラをゆっくり動かしてください"
        case .tappingFirstCorner:
            return "上から見て、物体の\n一方の角をタップ"
        case .tappingSecondCorner:
            return "対角の角をタップ"
        case .tappingHeight:
            return "横から見て\n物体の最上部をタップ"
        case .complete:
            return "測定完了！"
        }
    }

    var phaseIndex: Int {
        switch phase {
        case .detectingPlane: return 0
        case .tappingFirstCorner, .tappingSecondCorner: return 1
        case .tappingHeight: return 2
        case .complete: return 3
        }
    }

    func planeDetected(floorY y: Float) {
        guard phase == .detectingPlane else { return }
        floorY = y
        phase = .tappingFirstCorner
    }

    func tapFirst(_ point: SIMD3<Float>) {
        guard phase == .tappingFirstCorner else { return }
        firstCorner = point
        phase = .tappingSecondCorner
    }

    func tapSecond(_ point: SIMD3<Float>) {
        guard phase == .tappingSecondCorner, let first = firstCorner else { return }
        secondCorner = point

        let dx = abs(point.x - first.x) * 100
        let dz = abs(point.z - first.z) * 100
        let dims = [dx, dz].sorted(by: >)

        _ = dims  // store partial so next tap finishes
        phase = .tappingHeight
    }

    func tapTop(_ point: SIMD3<Float>) {
        guard phase == .tappingHeight,
              let first = firstCorner,
              let second = secondCorner else { return }

        let dx = abs(second.x - first.x) * 100
        let dz = abs(second.z - first.z) * 100
        let dims = [dx, dz].sorted(by: >)

        let h = max(abs(point.y - floorY) * 100, 0.5)

        measurement = ObjectMeasurement(
            width: dims[0],
            length: dims[1],
            height: h
        )
        phase = .complete
    }

    func reset() {
        phase = .detectingPlane
        measurement = nil
        firstCorner = nil
        secondCorner = nil
        floorY = 0
    }
}
