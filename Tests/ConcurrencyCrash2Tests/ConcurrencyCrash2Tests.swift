import XCTest
import class Foundation.Bundle
@testable import ConcurrencyCrash2

final class ConcurrencyCrash2Tests: XCTestCase {
    @available(macOS 12.0.0, *)
    func testMapParrallel() async throws {
        let inputSeconds = [5, 1, 4, 3, 2]
        let result = try await inputSeconds.mapParallel({ try await self.sleep(seconds: $0) })
        XCTAssertEqual(result, [5, 1, 4, 3, 2])
    }

    // sleeps for the given number of seconds and returns the given number of seconds
    @available(macOS 12.0.0, *)
    func sleep(seconds: Int) async throws -> Int {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
        return seconds
    }
}
