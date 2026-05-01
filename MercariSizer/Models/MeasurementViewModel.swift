import Foundation
import Combine
import simd

enum MeasurementPhase: Equatable {
    case calibrating    // 机に置いて床高さを記録
    case scanning       // Vision が上面矩形を自動検出
    case tappingHeight  // 最上部を1タップ
    case complete
}

@MainActor
final class MeasurementViewModel: ObservableObject {
    @Published var phase: MeasurementPhase = .calibrating
    @Published var measurement: ObjectMeasurement?
    @Published var calibrationCountdown: Int = 3
    @Published var isDetecting: Bool = false  // Vision が矩形を捉えているか

    private(set) var floorY: Float = 0
    private(set) var firstCorner: SIMD3<Float>?
    private(set) var secondCorner: SIMD3<Float>?

    var instructionText: String {
        switch phase {
        case .calibrating:
            return "画面を下にして\n机の上に置いてください"
        case .scanning:
            return "持ち上げて、上から\n物体全体が映るように構えてください"
        case .tappingHeight:
            return "横から見て\n物体の最上部をタップ"
        case .complete:
            return "測定完了！"
        }
    }

    var phaseIndex: Int {
        switch phase {
        case .calibrating: return 0
        case .scanning:    return 1
        case .tappingHeight: return 2
        case .complete:    return 3
        }
    }

    func calibrated(floorY y: Float) {
        guard phase == .calibrating else { return }
        floorY = y
        phase = .scanning
    }

    func confirmedTopRect(first: SIMD3<Float>, second: SIMD3<Float>) {
        guard phase == .scanning else { return }
        firstCorner = first
        secondCorner = second
        phase = .tappingHeight
    }

    func tapTop(_ point: SIMD3<Float>) {
        guard phase == .tappingHeight,
              let first = firstCorner,
              let second = secondCorner else { return }

        let dx   = abs(second.x - first.x) * 100
        let dz   = abs(second.z - first.z) * 100
        let dims = [dx, dz].sorted(by: >)
        let h    = max((point.y - floorY) * 100, 0.5)

        measurement = ObjectMeasurement(width: dims[0], length: dims[1], height: h)
        phase = .complete
    }

    func reset() {
        phase = .calibrating
        measurement = nil
        firstCorner = nil
        secondCorner = nil
        floorY = 0
        calibrationCountdown = 3
        isDetecting = false
    }
}
