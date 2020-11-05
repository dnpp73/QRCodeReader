import Foundation

enum Vote<E: Equatable & Hashable> {
    case blank
    case valid(_ value: E)
}

struct BallotBox<E: Equatable & Hashable> {

    // 最低限、白票よりも三分の一以上であれば勝利とする。何も検出されてない状況からの立ち上がりが若干早くなり 0.33 秒程度にするという気持ち。
    var winRate: Double = 0.333

    // カメラからの入力が 30 fps 想定なので、これで多数決による勝者の入れ替わりは概ね 0.5 秒の想定となる。
    // 60 にして試してみたけど、 1 秒かかるとなると少しもっさり感があった。
    var limit: Int = 30 {
        didSet {
            pruneBox()
        }
    }

    private var box: [Vote<E>] = []

    private mutating func pruneBox() {
        if limit <= 0 {
            return
        }
        while box.count >= limit {
            box.removeFirst()
        }
    }

    mutating func vote(_ vote: Vote<E>) {
        box.append(vote)
        pruneBox()
    }

    var winner: Vote<E> {
        let threshold = Int(ceil(Double(limit) * winRate))
        var count: [E: Int] = [:]
        for vote in box {
            switch vote {
            case .valid(let value):
                if let c = count[value] {
                    count[value] = c + 1
                } else {
                    count[value] = 0
                }
            case .blank:
                break
            }
        }
        let array: [(count: Int, value: E)] = count.map { ($0.value, $0.key) }
        let sorted = array.sorted { $0.count > $1.count }
        guard let winner = sorted.first else {
            return .blank
        }
        if winner.count <= threshold {
            return .blank
        } else {
            return .valid(winner.value)
        }
    }

}
