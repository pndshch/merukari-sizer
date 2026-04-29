import UIKit
import ARKit
import SceneKit
import Combine

final class ARViewController: UIViewController, ARSCNViewDelegate {

    // MARK: - Properties

    private let sceneView = ARSCNView()
    private let viewModel: MeasurementViewModel
    private var cancellables = Set<AnyCancellable>()
    private var overlayNodes: [SCNNode] = []
    private var planeNodes: [UUID: SCNNode] = [:]
    private var crosshairNode: SCNNode?
    private var firstMarkerNode: SCNNode?

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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
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
        sphere.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
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
            .sink { [weak self] phase in
                self?.handlePhaseChange(phase)
            }
            .store(in: &cancellables)
    }

    private func startARSession() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - Phase handling

    private func handlePhaseChange(_ phase: MeasurementPhase) {
        switch phase {
        case .detectingPlane:
            clearOverlay()
            planeNodes.values.forEach { $0.isHidden = false }
            crosshairNode?.isHidden = true
            startARSession()
        case .tappingFirstCorner:
            planeNodes.values.forEach { $0.isHidden = false }
            crosshairNode?.isHidden = false
        case .tappingSecondCorner:
            crosshairNode?.isHidden = false
        case .tappingHeight:
            planeNodes.values.forEach { $0.isHidden = true }
            crosshairNode?.isHidden = false
        case .complete:
            crosshairNode?.isHidden = true
        }
    }

    // MARK: - Tap

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)

        Task { @MainActor in
            switch viewModel.phase {
            case .tappingFirstCorner:
                guard let point = raycastOnPlane(at: location) else { return }
                placeMarker(at: point, color: .systemOrange, size: 0.012)
                firstMarkerNode = overlayNodes.last
                viewModel.tapFirst(point)

            case .tappingSecondCorner:
                guard let point = raycastOnPlane(at: location),
                      let first = viewModel.firstCorner else { return }
                placeMarker(at: point, color: .systemOrange, size: 0.012)
                drawRectangle(from: first, to: point, at: first.y)
                viewModel.tapSecond(point)

            case .tappingHeight:
                guard let point = raycastAny(at: location) else { return }
                let floorY = viewModel.floorY
                let bottom = SIMD3<Float>(point.x, floorY, point.z)
                placeMarker(at: point, color: .systemRed, size: 0.012)
                addLine(from: bottom, to: point, color: .systemPurple)
                viewModel.tapTop(point)

            default:
                break
            }
        }
    }

    // MARK: - Raycasting

    private func raycastOnPlane(at location: CGPoint) -> SIMD3<Float>? {
        if let query = sceneView.raycastQuery(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal),
           let result = sceneView.session.raycast(query).first {
            return result.worldTransform.translation
        }
        if let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal),
           let result = sceneView.session.raycast(query).first {
            return result.worldTransform.translation
        }
        return nil
    }

    private func raycastAny(at location: CGPoint) -> SIMD3<Float>? {
        if let query = sceneView.raycastQuery(from: location, allowing: .existingPlaneGeometry, alignment: .any),
           let result = sceneView.session.raycast(query).first {
            return result.worldTransform.translation
        }
        if let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .any),
           let result = sceneView.session.raycast(query).first {
            return result.worldTransform.translation
        }
        return nil
    }

    // MARK: - AR Visuals

    private func placeMarker(at position: SIMD3<Float>, color: UIColor, size: CGFloat) {
        let sphere = SCNSphere(radius: size)
        sphere.firstMaterial?.diffuse.contents = color
        sphere.firstMaterial?.lightingModel = .constant
        let node = SCNNode(geometry: sphere)
        node.simdWorldPosition = position
        sceneView.scene.rootNode.addChildNode(node)
        overlayNodes.append(node)
    }

    private func drawRectangle(from p1: SIMD3<Float>, to p2: SIMD3<Float>, at y: Float) {
        let corners: [SIMD3<Float>] = [
            SIMD3(p1.x, y, p1.z),
            SIMD3(p2.x, y, p1.z),
            SIMD3(p2.x, y, p2.z),
            SIMD3(p1.x, y, p2.z),
        ]
        for i in 0..<4 {
            addLine(from: corners[i], to: corners[(i + 1) % 4], color: .systemYellow)
        }
    }

    private func addLine(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor) {
        let startVec = SCNVector3(start.x, start.y, start.z)
        let endVec = SCNVector3(end.x, end.y, end.z)
        let source = SCNGeometrySource(vertices: [startVec, endVec])
        let indices: [UInt16] = [0, 1]
        let data = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
        let element = SCNGeometryElement(
            data: data,
            primitiveType: .line,
            primitiveCount: 1,
            bytesPerIndex: MemoryLayout<UInt16>.size
        )
        let geometry = SCNGeometry(sources: [source], elements: [element])
        geometry.firstMaterial?.diffuse.contents = color
        geometry.firstMaterial?.lightingModel = .constant
        let node = SCNNode(geometry: geometry)
        sceneView.scene.rootNode.addChildNode(node)
        overlayNodes.append(node)
    }

    private func clearOverlay() {
        overlayNodes.forEach { $0.removeFromParentNode() }
        overlayNodes.removeAll()
        firstMarkerNode = nil
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              planeAnchor.alignment == .horizontal else { return }

        let width = CGFloat(planeAnchor.planeExtent.width)
        let height = CGFloat(planeAnchor.planeExtent.height)
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.25)
        plane.firstMaterial?.isDoubleSided = true

        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = SIMD3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2
        node.addChildNode(planeNode)
        planeNodes[anchor.identifier] = planeNode

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let worldY = planeAnchor.transform.columns.3.y
            self.viewModel.planeDetected(floorY: worldY)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              planeAnchor.alignment == .horizontal,
              let planeNode = planeNodes[anchor.identifier],
              let plane = planeNode.geometry as? SCNPlane else { return }

        plane.width = CGFloat(planeAnchor.planeExtent.width)
        plane.height = CGFloat(planeAnchor.planeExtent.height)
        planeNode.simdPosition = SIMD3(planeAnchor.center.x, 0, planeAnchor.center.z)
    }

    // Live crosshair tracking
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard viewModel.phase != .detectingPlane,
              viewModel.phase != .complete else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let center = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
            let hit: SIMD3<Float>?
            if self.viewModel.phase == .tappingHeight {
                hit = self.raycastAny(at: center)
            } else {
                hit = self.raycastOnPlane(at: center)
            }
            if let pos = hit {
                self.crosshairNode?.isHidden = false
                self.crosshairNode?.simdWorldPosition = pos
            } else {
                self.crosshairNode?.isHidden = true
            }
        }
    }
}

// MARK: - simd_float4x4 helper

private extension simd_float4x4 {
    var translation: SIMD3<Float> {
        SIMD3(columns.3.x, columns.3.y, columns.3.z)
    }
}
