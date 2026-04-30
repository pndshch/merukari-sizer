import UIKit
import ARKit
import SceneKit
import CoreMotion
import Combine
import AVFoundation

final class ARViewController: UIViewController, ARSCNViewDelegate {

    // MARK: - Properties

    private let sceneView = ARSCNView()
    private let viewModel: MeasurementViewModel
    private var cancellables = Set<AnyCancellable>()
    private var overlayNodes: [SCNNode] = []
    private var crosshairNode: SCNNode?

    // Calibration
    private let motionManager = CMMotionManager()
    private let speechSynth = AVSpeechSynthesizer()
    private var calibrationTimer: Timer?
    private var countdownValue = 3
    private var isCountingDown = false

    // MARK: - Init

    init(viewModel: MeasurementViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        setupCrosshair()
        setupGestures()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
        startMotionUpdates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        motionManager.stopDeviceMotionUpdates()
        calibrationTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupSceneView() {
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling2X
    }

    private func setupCrosshair() {
        let sphere = SCNSphere(radius: 0.008)
        sphere.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.85)
        sphere.firstMaterial?.lightingModel = .constant
        crosshairNode = SCNNode(geometry: sphere)
        crosshairNode?.isHidden = true
        sceneView.scene.rootNode.addChildNode(crosshairNode!)
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tap)
    }

    private func bindViewModel() {
        viewModel.$phase
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in self?.handlePhaseChange(phase) }
            .store(in: &cancellables)
    }

    private func startARSession() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []          // 平面検出不要
        config.environmentTexturing = .none
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = []
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.handleMotionUpdate(motion)
        }
    }

    // MARK: - Phase

    private func handlePhaseChange(_ phase: MeasurementPhase) {
        switch phase {
        case .calibrating:
            clearOverlay()
            crosshairNode?.isHidden = true
            isCountingDown = false
            calibrationTimer?.invalidate()
        case .tappingFirstCorner:
            crosshairNode?.isHidden = false
            haptic(.light)
        case .tappingSecondCorner:
            crosshairNode?.isHidden = false
            haptic(.selection)
        case .tappingHeight:
            crosshairNode?.isHidden = false
            haptic(.selection)
        case .complete:
            crosshairNode?.isHidden = true
            haptic(.success)
        }
    }

    // MARK: - Calibration (gravity detection)

    private func handleMotionUpdate(_ motion: CMDeviceMotion) {
        guard viewModel.phase == .calibrating else {
            if isCountingDown { stopCountdown() }
            return
        }

        // gravity.z ≈ +1 → 画面下向き（カメラが上を向いている = 机に伏せた状態）
        let isFaceDown = motion.gravity.z > 0.82

        if isFaceDown && !isCountingDown {
            startCountdown()
        } else if !isFaceDown && isCountingDown {
            stopCountdown()
        }
    }

    private func startCountdown() {
        isCountingDown = true
        countdownValue = 3
        Task { @MainActor in viewModel.calibrationCountdown = 3 }
        speak("さん")

        calibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            self.countdownValue -= 1
            Task { @MainActor in self.viewModel.calibrationCountdown = self.countdownValue }

            switch self.countdownValue {
            case 2: self.speak("に")
            case 1: self.speak("いち")
            default: break
            }

            if self.countdownValue <= 0 {
                t.invalidate()
                self.isCountingDown = false
                self.finishCalibration()
            }
        }
    }

    private func stopCountdown() {
        isCountingDown = false
        calibrationTimer?.invalidate()
        speechSynth.stopSpeaking(at: .immediate)
        countdownValue = 3
        Task { @MainActor in viewModel.calibrationCountdown = 3 }
    }

    private func finishCalibration() {
        guard let frame = sceneView.session.currentFrame else { return }
        // 机に伏せた状態: カメラ位置 ≈ 床 + 本体厚み(8mm)
        let cameraY = frame.camera.transform.columns.3.y
        let floorY  = cameraY - 0.008

        // 画面が見えない状態でも「今！」がわかるように: 音声 + 強いバイブ×3
        speak("はなして！")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }

        Task { @MainActor in viewModel.calibrated(floorY: floorY) }
    }

    // MARK: - Speech

    private func speak(_ text: String) {
        // AVAudioSession をスピーカー出力に固定（机に伏せても聞こえるように）
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .defaultToSpeaker)
        try? AVAudioSession.sharedInstance().setActive(true)
        speechSynth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        u.rate  = 0.42
        u.pitchMultiplier = 1.1
        speechSynth.speak(u)
    }

    // MARK: - Tap

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: sceneView)

        Task { @MainActor in
            switch viewModel.phase {
            case .tappingFirstCorner:
                guard let pt = rayHitFloor(at: loc) else { return }
                placeMarker(at: pt, color: .systemOrange)
                viewModel.tapFirst(pt)

            case .tappingSecondCorner:
                guard let pt = rayHitFloor(at: loc),
                      let first = viewModel.firstCorner else { return }
                placeMarker(at: pt, color: .systemOrange)
                drawRectangle(from: first, to: pt, floorY: viewModel.floorY)
                viewModel.tapSecond(pt)

            case .tappingHeight:
                guard let pt = rayHitVerticalPlaneAtObject(at: loc) else { return }
                let bottom = SIMD3<Float>(pt.x, viewModel.floorY, pt.z)
                placeMarker(at: pt, color: .systemRed)
                addLine(from: bottom, to: pt, color: .systemPurple)
                viewModel.tapTop(pt)

            default:
                break
            }
        }
    }

    // MARK: - Ray casting (SCNView unprojection)

    /// スクリーン座標 → ワールド空間のレイ（origin, normalized direction）
    private func worldRay(at screenPoint: CGPoint) -> (origin: SIMD3<Float>, dir: SIMD3<Float>) {
        let near = sceneView.unprojectPoint(SCNVector3(Float(screenPoint.x), Float(screenPoint.y), 0))
        let far  = sceneView.unprojectPoint(SCNVector3(Float(screenPoint.x), Float(screenPoint.y), 1))
        let o = SIMD3<Float>(near.x, near.y, near.z)
        let d = normalize(SIMD3<Float>(far.x - near.x, far.y - near.y, far.z - near.z))
        return (o, d)
    }

    /// レイ × 水平面 (Y = floorY) の交点
    private func rayHitFloor(at screenPoint: CGPoint) -> SIMD3<Float>? {
        let (origin, dir) = worldRay(at: screenPoint)
        guard abs(dir.y) > 0.001 else { return nil }
        let t = (viewModel.floorY - origin.y) / dir.y
        guard t > 0 else { return nil }
        return origin + t * dir
    }

    /// レイ × 物体中心を通る鉛直面の交点（高さ計測用）
    private func rayHitVerticalPlaneAtObject(at screenPoint: CGPoint) -> SIMD3<Float>? {
        guard let p1 = viewModel.firstCorner,
              let p2 = viewModel.secondCorner,
              let frame = sceneView.session.currentFrame else { return nil }

        let objCenter = SIMD3<Float>((p1.x + p2.x) / 2, viewModel.floorY, (p1.z + p2.z) / 2)
        let camXZ = SIMD3<Float>(frame.camera.transform.columns.3.x, 0, frame.camera.transform.columns.3.z)
        let toCam = camXZ - SIMD3<Float>(objCenter.x, 0, objCenter.z)
        guard simd_length(toCam) > 0.01 else { return nil }
        let normal = normalize(toCam)

        let (origin, dir) = worldRay(at: screenPoint)
        let denom = simd_dot(normal, dir)
        guard abs(denom) > 0.001 else { return nil }
        let t = simd_dot(normal, objCenter - origin) / denom
        guard t > 0 else { return nil }
        return origin + t * dir
    }

    // MARK: - AR Visuals

    private func placeMarker(at pos: SIMD3<Float>, color: UIColor) {
        let sphere = SCNSphere(radius: 0.012)
        sphere.firstMaterial?.diffuse.contents = color
        sphere.firstMaterial?.lightingModel = .constant
        let node = SCNNode(geometry: sphere)
        node.simdWorldPosition = pos
        sceneView.scene.rootNode.addChildNode(node)
        overlayNodes.append(node)
    }

    private func drawRectangle(from p1: SIMD3<Float>, to p2: SIMD3<Float>, floorY y: Float) {
        let corners: [SIMD3<Float>] = [
            SIMD3(p1.x, y, p1.z), SIMD3(p2.x, y, p1.z),
            SIMD3(p2.x, y, p2.z), SIMD3(p1.x, y, p2.z),
        ]
        for i in 0..<4 { addLine(from: corners[i], to: corners[(i + 1) % 4], color: .systemYellow) }
    }

    private func addLine(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor) {
        let src = SCNGeometrySource(vertices: [SCNVector3(start), SCNVector3(end)])
        let data = Data(bytes: [UInt16(0), UInt16(1)], count: 4)
        let elem = SCNGeometryElement(data: data, primitiveType: .line, primitiveCount: 1, bytesPerIndex: 2)
        let geo = SCNGeometry(sources: [src], elements: [elem])
        geo.firstMaterial?.diffuse.contents = color
        geo.firstMaterial?.lightingModel = .constant
        let node = SCNNode(geometry: geo)
        sceneView.scene.rootNode.addChildNode(node)
        overlayNodes.append(node)
    }

    private func clearOverlay() {
        overlayNodes.forEach { $0.removeFromParentNode() }
        overlayNodes.removeAll()
    }

    // MARK: - ARSCNViewDelegate (crosshair tracking)

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard viewModel.phase != .calibrating, viewModel.phase != .complete else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let center = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
            let hit: SIMD3<Float>?
            if self.viewModel.phase == .tappingHeight {
                hit = self.rayHitVerticalPlaneAtObject(at: center)
            } else {
                hit = self.rayHitFloor(at: center)
            }
            if let pos = hit {
                self.crosshairNode?.isHidden = false
                self.crosshairNode?.simdWorldPosition = pos
            } else {
                self.crosshairNode?.isHidden = true
            }
        }
    }

    // MARK: - Haptics

    private func haptic(_ style: HapticStyle) {
        switch style {
        case .light:   UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .selection: UISelectionFeedbackGenerator().selectionChanged()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    private enum HapticStyle { case light, selection, success }
}

private extension SCNVector3 {
    init(_ v: SIMD3<Float>) { self.init(v.x, v.y, v.z) }
}
