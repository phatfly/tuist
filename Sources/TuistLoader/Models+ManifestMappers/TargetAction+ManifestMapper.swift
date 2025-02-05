import Foundation
import ProjectDescription
import TSCBasic
import TuistCore
import TuistGraph
import TuistSupport

extension TuistGraph.TargetScript {
    /// Maps a ProjectDescription.TargetAction instance into a TuistGraph.TargetAction model.
    /// - Parameters:
    ///   - manifest: Manifest representation of target action.
    ///   - generatorPaths: Generator paths.
    static func from(manifest: ProjectDescription.TargetScript, generatorPaths: GeneratorPaths) throws -> TuistGraph
        .TargetScript
    {
        let name = manifest.name
        let order = TuistGraph.TargetScript.Order.from(manifest: manifest.order)
        let inputPaths = try absolutePaths(for: manifest.inputPaths, generatorPaths: generatorPaths)
        let inputFileListPaths = try absolutePaths(for: manifest.inputFileListPaths, generatorPaths: generatorPaths)
        let outputPaths = try absolutePaths(for: manifest.outputPaths, generatorPaths: generatorPaths)
        let outputFileListPaths = try absolutePaths(for: manifest.outputFileListPaths, generatorPaths: generatorPaths)
        let basedOnDependencyAnalysis = manifest.basedOnDependencyAnalysis
        let runForInstallBuildsOnly = manifest.runForInstallBuildsOnly
        let affectsBuiltProduct = manifest.affectsBuiltProduct
        let shellPath = manifest.shellPath

        let script: TuistGraph.TargetScript.Script
        switch manifest.script {
        case let .embedded(text, affectsBuiltProduct):
            script = .embedded(text, affectsBuiltProduct: affectsBuiltProduct)

        case let .scriptPath(path, arguments, affectsBuiltProduct):
            let scriptPath = try generatorPaths.resolve(path: path)
            script = .scriptPath(path: scriptPath, args: arguments, affectsBuiltProduct: affectsBuiltProduct)

        case let .tool(tool, arguments, affectsBuiltProduct):
            script = .tool(path: tool, args: arguments, affectsBuiltProduct: affectsBuiltProduct)
        }

        return TargetScript(
            name: name,
            order: order,
            script: script,
            inputPaths: inputPaths,
            inputFileListPaths: inputFileListPaths,
            outputPaths: outputPaths,
            outputFileListPaths: outputFileListPaths,
            basedOnDependencyAnalysis: basedOnDependencyAnalysis,
            runForInstallBuildsOnly: runForInstallBuildsOnly,
            affectsBuiltProduct: affectsBuiltProduct,
            shellPath: shellPath
        )
    }

    private static func absolutePaths(for paths: [Path], generatorPaths: GeneratorPaths) throws -> [AbsolutePath] {
        try paths.map { (path: Path) -> [AbsolutePath] in
            // avoid globbing paths that contain variables
            if path.pathString.contains("$") {
                return [try generatorPaths.resolve(path: path)]
            }
            let absolutePath = try generatorPaths.resolve(path: path)
            let base = AbsolutePath(absolutePath.dirname)
            return try base.throwingGlob(absolutePath.basename)
        }.reduce([], +)
    }
}

extension TuistGraph.TargetScript.Order {
    /// Maps a ProjectDescription.TargetAction.Order instance into a TuistGraph.TargetAction.Order model.
    /// - Parameters:
    ///   - manifest: Manifest representation of target action order.
    ///   - generatorPaths: Generator paths.
    static func from(manifest: ProjectDescription.TargetScript.Order) -> TuistGraph.TargetScript.Order {
        switch manifest {
        case .pre:
            return .pre
        case .post:
            return .post
        }
    }
}
