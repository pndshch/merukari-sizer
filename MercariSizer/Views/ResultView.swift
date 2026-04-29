import SwiftUI

struct ResultView: View {
    let measurement: ObjectMeasurement
    let onRetry: () -> Void

    private var options: [ShippingSize] { recommendedOptions(for: measurement) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.93).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    dimensionsCard
                    recommendationsSection
                    retryButton
                }
                .padding()
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("測定結果")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Text("メルカリ便おすすめサイズ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "cube.transparent")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
        }
    }

    private var dimensionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("サイズ", systemImage: "ruler")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 0) {
                dimensionItem(label: "横", value: measurement.width)
                Divider().frame(height: 40).background(.secondary)
                dimensionItem(label: "奥行", value: measurement.length)
                Divider().frame(height: 40).background(.secondary)
                dimensionItem(label: "高さ", value: measurement.height)
            }

            HStack {
                Text("3辺合計")
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f cm", measurement.girth))
                    .foregroundColor(.white)
                    .bold()
            }
            .font(.subheadline)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.08)))
    }

    private func dimensionItem(label: String, value: Float) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.1f", value))
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("cm")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("おすすめ配送", systemImage: "shippingbox")
                .font(.headline)
                .foregroundColor(.white)

            if options.isEmpty {
                Text("対応するメルカリ便サイズが見つかりませんでした。\n寸法を確認してください。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.06)))
            } else {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    ShippingOptionRow(option: option, isBestPick: index == 0)
                }
            }
        }
    }

    private var retryButton: some View {
        Button(action: onRetry) {
            Label("もう一度測定する", systemImage: "arrow.counterclockwise")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.12)))
                .foregroundColor(.white)
        }
    }
}

// MARK: - ShippingOptionRow

private struct ShippingOptionRow: View {
    let option: ShippingSize
    let isBestPick: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(option.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    if isBestPick {
                        Text("最安")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.orange))
                            .foregroundColor(.white)
                    }
                }
                Text(option.service)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(option.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("¥\(option.price)")
                .font(.title3.bold())
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isBestPick ? .white.opacity(0.12) : .white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isBestPick ? Color.orange.opacity(0.5) : .clear, lineWidth: 1)
        )
    }
}
