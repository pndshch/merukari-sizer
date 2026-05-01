import SwiftUI

struct InstructionView: View {
    @ObservedObject var viewModel: MeasurementViewModel

    var body: some View {
        VStack(spacing: 16) {
            phaseGuide
            StepDots(currentStep: viewModel.phaseIndex)
            Text(viewModel.instructionText)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: 24).fill(.black.opacity(0.78)))
        .padding(.horizontal, 20)
        .animation(.easeInOut, value: viewModel.phase)
    }

    @ViewBuilder
    private var phaseGuide: some View {
        switch viewModel.phase {
        case .calibrating:
            CalibrationGuide(countdown: viewModel.calibrationCountdown)
        case .scanning:
            AutoDetectGuide(isDetecting: viewModel.isDetecting)
        case .tappingHeight:
            PhaseIcon(symbolName: "arrow.up.and.down.circle.fill", color: .purple, label: "高さ")
        case .complete:
            EmptyView()
        }
    }
}

// MARK: - Calibration guide

private struct CalibrationGuide: View {
    let countdown: Int
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 16) {
            // Phone face-down illustration
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 36, height: 58)
                // Camera dots on top (back of phone facing up)
                VStack(spacing: 3) {
                    Circle().fill(Color.white.opacity(0.6)).frame(width: 8, height: 8)
                    Circle().fill(Color.white.opacity(0.4)).frame(width: 5, height: 5)
                }
                .offset(y: -10)
            }
            .scaleEffect(bounce ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: bounce)

            // Countdown
            if countdown < 3 {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.4), lineWidth: 3)
                        .frame(width: 48, height: 48)
                    Text("\(countdown)")
                        .font(.title.bold())
                        .foregroundColor(.green)
                        .contentTransition(.numericText())
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green.opacity(0.8))
                    .transition(.opacity)
            }
        }
        .onAppear { bounce = true }
        .animation(.easeInOut, value: countdown)
    }
}

// MARK: - Phase icon

private struct PhaseIcon: View {
    let symbolName: String
    let color: Color
    let label: String
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 28))
                .foregroundColor(color)
                .scaleEffect(bounce ? 1.15 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5).repeatForever(autoreverses: true), value: bounce)
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(color.opacity(0.25)))
                .foregroundColor(color)
        }
        .onAppear { bounce = true }
    }
}

// MARK: - Auto detect guide

private struct AutoDetectGuide: View {
    let isDetecting: Bool
    @State private var spin = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isDetecting ? Color.green : Color.white.opacity(0.4), lineWidth: 2)
                    .frame(width: 44, height: 36)
                    .animation(.easeInOut(duration: 0.3), value: isDetecting)

                // corner brackets
                ForEach(0..<4, id: \.self) { i in
                    let flip = CGSize(width: i < 2 ? 1 : -1, height: i % 2 == 0 ? 1 : -1)
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: 7))
                        p.addLine(to: .zero)
                        p.addLine(to: CGPoint(x: 7, y: 0))
                    }
                    .stroke(isDetecting ? Color.green : Color.white.opacity(0.6), lineWidth: 2)
                    .frame(width: 44, height: 36)
                    .scaleEffect(x: flip.width, y: flip.height)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                if isDetecting {
                    Text("物体を検出中…")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                } else {
                    Text("物体を探しています")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(Color.white.opacity(spin ? 0.9 : 0.2))
                                .frame(width: 5, height: 5)
                                .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2), value: spin)
                        }
                    }
                }
            }
        }
        .onAppear { spin = true }
    }
}

// MARK: - Scanning animation (unused, kept for reference)

private struct ScanningGuide: View {
    @State private var pulse = false
    @State private var tilt  = false
    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.green.opacity(pulse ? 0 : 0.6), lineWidth: 1.5)
                    .frame(width: 54 + CGFloat(i) * 18)
                    .scaleEffect(pulse ? 1.5 : 1.0)
                    .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(Double(i) * 0.45), value: pulse)
            }
            Image(systemName: "iphone.rear.camera")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.green)
                .rotationEffect(.degrees(tilt ? -18 : 18))
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: tilt)
        }
        .frame(height: 70)
        .onAppear { pulse = true; tilt = true }
    }
}

// MARK: - Step dots

private struct StepDots: View {
    let currentStep: Int
    private let totalSteps = 4
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep ? Color.accentColor : Color.white.opacity(0.25))
                    .frame(width: i == currentStep ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
}
