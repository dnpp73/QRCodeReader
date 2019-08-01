import Foundation

enum Vote<E: Equatable & Hashable> {
    case blank
    case valid(_ value: E)
}

struct BallotBox<E: Equatable & Hashable> {

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

        print(winner)
    }

    var winner: Vote<E> {
        var blankCount = 0
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
                blankCount += 1
            }
        }
        let array: [(count: Int, value: E)] = count.map { ($0.value, $0.key) }
        let sorted = array.sorted { $0.count > $1.count }
        guard let many = sorted.first else {
            return .blank
        }
        if many.count < blankCount {
            return .blank
        } else {
            return .valid(many.value)
        }
    }

}
