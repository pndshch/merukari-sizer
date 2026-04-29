import SwiftUI

struct ARMeasureView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: MeasurementViewModel

    func makeUIViewController(context: Context) -> ARViewController {
        ARViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}
