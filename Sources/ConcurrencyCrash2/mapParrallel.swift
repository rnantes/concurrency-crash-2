import Foundation

private struct TransformResult<T> {
    var id: UUID
    var index: Int
    var transformedElement: T

    init(index: Int, transformedElement: T) {
        self.id = UUID()
        self.index = index
        self.transformedElement = transformedElement
    }
}

public extension Collection {
    @available(macOS 12.0.0, *)
    func mapParallel<T>(_ transform: @escaping (Element) async throws -> T) async throws -> [T] {
        let transfromResults = try await self.mapParallelTransformResult({ try await transform($0) })
        let transfromResultsSorted = transfromResults.sorted(by: { $0.index < $1.index } ).map({ $0.transformedElement })
        return transfromResultsSorted
    }

    @available(macOS 12.0.0, *)
    /// Executes a map in parallel and returns a generic`TransformResult` struct that contains the transformed element and it's the index in the input array and a uuid identifier
    private func mapParallelTransformResult<T>(_ transform: @escaping (Element) async throws -> T) async throws -> [TransformResult<T>] {
        return try await withThrowingTaskGroup(of: TransformResult<T>.self) { group in
            var transformedResults: [TransformResult<T>] = []

            // Create a new child task for each element transform
            for (i, element) in self.enumerated() {
                group.addTask {
                    let transfromedElement = try await transform(element)
                    let transformResult = TransformResult<T>.init(index: i, transformedElement: transfromedElement)
                    return transformResult
                }
            }

            // Wait for all of the transforms to complete, collecting the transform elements into
            // the result array in whatever order they're ready.
            for try await transformedResult in group {
                transformedResults.append(transformedResult)
                try Task.checkCancellation()
            }

            return transformedResults
        }
    }
}
