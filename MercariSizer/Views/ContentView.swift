import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MeasurementViewModel()

    var body: some View {
        ZStack {
            ARMeasureView(viewModel: viewModel)
                .ignoresSafeArea()

            VStack {
                Spacer()

                if viewModel.phase != .complete {
                    InstructionView(viewModel: viewModel)
                        .padding(.bottom, 40)
                }
            }

            if viewModel.phase == .complete, let measurement = viewModel.measurement {
                ResultView(measurement: measurement, onRetry: {
                    withAnimation { viewModel.reset() }
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.phase)
    }
}
