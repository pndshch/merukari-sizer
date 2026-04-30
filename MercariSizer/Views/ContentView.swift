import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MeasurementViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

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

            // Help button (top-right) to re-open onboarding anytime
            if viewModel.phase != .complete {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showOnboarding = true
                        } label: {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.phase)
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
            hasSeenOnboarding = true
        }) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }
}
