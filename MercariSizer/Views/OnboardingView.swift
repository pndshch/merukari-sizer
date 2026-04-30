import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbolName: "camera.viewfinder",
            symbolColor: .accentColor,
            title: "MercariSizer",
            description: "カメラだけで物体のサイズを測定して、メルカリ便の最適な配送サイズを自動でおすすめします。定規不要！"
        ),
        OnboardingPage(
            symbolName: "iphone.rear.camera",
            symbolColor: .green,
            title: "床をスキャン",
            description: "物体を床や机に置いて、カメラを斜め下に向けながら\nゆっくり左右に動かしてください。\n\n緑のグリッドが出たらスキャン完了です。"
        ),
        OnboardingPage(
            symbolName: "hand.tap.fill",
            symbolColor: .orange,
            title: "対角2点をタップ",
            description: "真上から見て、物体の\n対角の角を2回タップ。\n\n長さと幅が計算されます。"
        ),
        OnboardingPage(
            symbolName: "arrow.up.and.down.circle.fill",
            symbolColor: .purple,
            title: "横から高さを測定",
            description: "横から見て、物体の\n最上部をタップ。\n\n3辺の測定完了！配送サイズが決まります。"
        ),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, pg in
                        pageContent(pg, isFirst: index == 0)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                bottomBar
                    .padding(.bottom, 40)
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Page content

    private func pageContent(_ pg: OnboardingPage, isFirst: Bool) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(pg.symbolColor.opacity(0.15))
                    .frame(width: 160, height: 160)

                Image(systemName: pg.symbolName)
                    .font(.system(size: isFirst ? 60 : 52, weight: .light))
                    .foregroundColor(pg.symbolColor)
            }

            VStack(spacing: 14) {
                Text(pg.title)
                    .font(isFirst ? .largeTitle.bold() : .title2.bold())
                    .foregroundColor(.white)

                Text(pg.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 20) {
            // Dot indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Color.white : Color.white.opacity(0.3))
                        .frame(width: i == page ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: page)
                }
            }

            if page < pages.count - 1 {
                HStack {
                    Button("スキップ") {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        HStack {
                            Text("次へ")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.accentColor))
                        .foregroundColor(.white)
                    }
                }
            } else {
                Button {
                    isPresented = false
                } label: {
                    Text("測定を始める")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.accentColor))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

private struct OnboardingPage {
    let symbolName: String
    let symbolColor: Color
    let title: String
    let description: String
}
