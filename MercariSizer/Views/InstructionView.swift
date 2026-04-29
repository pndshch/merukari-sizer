import SwiftUI

struct InstructionView: View {
    @ObservedObject var viewModel: MeasurementViewModel

    var body: some View {
        VStack(spacing: 12) {
            StepDots(currentStep: viewModel.phaseIndex)

            Text(viewModel.instructionText)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.72))
        )
        .padding(.horizontal, 20)
        .animation(.easeInOut, value: viewModel.phase)
    }
}

private struct StepDots: View {
    let currentStep: Int
    private let totalSteps = 4

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep ? Color.accentColor : Color.white.opacity(0.3))
                    .frame(width: i == currentStep ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
}
