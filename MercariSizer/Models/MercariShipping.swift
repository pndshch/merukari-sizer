import Foundation

struct ShippingSize {
    let name: String
    let service: String
    let price: Int
    let note: String
    let maxLongest: Float?   // cm - 最長辺
    let maxMiddle: Float?    // cm - 中辺
    let maxShortest: Float?  // cm - 最短辺（厚さ）
    let maxGirth: Float?     // cm - 3辺合計
    let maxWeight: Float     // kg

    func fits(_ m: ObjectMeasurement) -> Bool {
        let dims = [m.width, m.length, m.height].sorted(by: >)
        let longest = dims[0]
        let middle = dims[1]
        let shortest = dims[2]

        if let maxGirth, m.girth > maxGirth { return false }
        if let maxLongest, longest > maxLongest { return false }
        if let maxMiddle, middle > maxMiddle { return false }
        if let maxShortest, shortest > maxShortest { return false }

        return true
    }
}

let allShippingSizes: [ShippingSize] = [
    // ─── らくらくメルカリ便 ───────────────────────────────────────
    ShippingSize(
        name: "ネコポス",
        service: "らくらくメルカリ便",
        price: 210,
        note: "ポスト投函・追跡あり",
        maxLongest: 31.2,
        maxMiddle: 22.8,
        maxShortest: 3.0,
        maxGirth: nil,
        maxWeight: 1.0
    ),
    ShippingSize(
        name: "宅急便コンパクト（BOX型）",
        service: "らくらくメルカリ便",
        price: 520,  // 450円 + 専用BOX70円
        note: "専用BOX使用（別途70円）",
        maxLongest: 25.0,
        maxMiddle: 20.0,
        maxShortest: 5.0,
        maxGirth: nil,
        maxWeight: 999.0
    ),
    ShippingSize(
        name: "宅急便コンパクト（薄型）",
        service: "らくらくメルカリ便",
        price: 520,
        note: "専用BOX使用（別途70円）",
        maxLongest: 34.0,
        maxMiddle: 24.8,
        maxShortest: 2.4,
        maxGirth: nil,
        maxWeight: 999.0
    ),
    ShippingSize(
        name: "宅急便 60サイズ",
        service: "らくらくメルカリ便",
        price: 750,
        note: "3辺合計60cm以内",
        maxLongest: nil,
        maxMiddle: nil,
        maxShortest: nil,
        maxGirth: 60.0,
        maxWeight: 2.0
    ),
    ShippingSize(
        name: "宅急便 80サイズ",
        service: "らくらくメルカリ便",
        price: 850,
        note: "3辺合計80cm以内",
        maxLongest: nil,
        maxMiddle: nil,
        maxShortest: nil,
        maxGirth: 80.0,
        maxWeight: 5.0
    ),
    ShippingSize(
        name: "宅急便 100サイズ",
        service: "らくらくメルカリ便",
        price: 1050,
        note: "3辺合計100cm以内",
        maxLongest: nil,
        maxMiddle: nil,
        maxShortest: nil,
        maxGirth: 100.0,
        maxWeight: 10.0
    ),
    ShippingSize(
        name: "宅急便 120サイズ",
        service: "らくらくメルカリ便",
        price: 1200,
        note: "3辺合計120cm以内",
        maxLongest: nil,
        maxMiddle: nil,
        maxShortest: nil,
        maxGirth: 120.0,
        maxWeight: 15.0
    ),
    ShippingSize(
        name: "宅急便 140サイズ",
        service: "らくらくメルカリ便",
        price: 1450,
        note: "3辺合計140cm以内",
        maxLongest: nil,
        maxMiddle: nil,
        maxShortest: nil,
        maxGirth: 140.0,
        maxWeight: 20.0
    ),
    ShippingSize(
        name: "宅急便 160サイズ",
        service: "らくらくメルカリ便",
        price: 1700,
        note: "3辺合計160cm以内",
        maxLongest: nil,
        maxMiddle: nil,
        maxShortest: nil,
        maxGirth: 160.0,
        maxWeight: 25.0
    ),

    // ─── ゆうゆうメルカリ便 ──────────────────────────────────────
    ShippingSize(
        name: "ゆうパケット",
        service: "ゆうゆうメルカリ便",
        price: 230,
        note: "ポスト投函・追跡あり",
        maxLongest: 34.0,
        maxMiddle: nil,
        maxShortest: 3.0,
        maxGirth: 60.0,
        maxWeight: 1.0
    ),
    ShippingSize(
        name: "ゆうパック 60サイズ",
        service: "ゆうゆうメルカリ便",
        price: 770,
        note: "3辺合計60cm以内・重さ25kgまで",
        maxLongest: nil,
        maxMiddle: nil,
        maxShortest: nil,
        maxGirth: 60.0,
        maxWeight: 25.0
    ),
    ShippingSize(
        name: "ゆうパック 80サイズ",
        service: "ゆうゆうメルカリ便",
        price: 870,
        note: "3辺合計80cm以内・重さ25kgまで",
        maxLongest: nil,
        maxMiddle: nil,
        maxShortest: nil,
        maxGirth: 80.0,
        maxWeight: 25.0
    ),
    ShippingSize(
        name: "ゆうパック 100サイズ",
        service: "ゆうゆうメルカリ便",
        price: 1070,
        note: "3辺合計100cm以内・重さ25kgまで",
        maxLongest: nil,
        maxMiddle: nil,
        maxShortest: nil,
        maxGirth: 100.0,
        maxWeight: 25.0
    ),
]

func recommendedOptions(for measurement: ObjectMeasurement) -> [ShippingSize] {
    allShippingSizes
        .filter { $0.fits(measurement) }
        .sorted { $0.price < $1.price }
}
