//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import OpenAPIKit

extension Declaration {

    /// Returns the declaration with the provided macros attached after any top comment.
    /// - Parameter macros: The macros to attach.
    /// - Returns: The declaration, unchanged if `macros` is empty.
    func attaching(_ macros: [AttachedMacro]) -> Self {
        guard !macros.isEmpty else { return self }
        let attributes = macros.map(AttributeDescription.init)
        if case .commentable(let comment, let declaration) = self {
            return .commentable(comment, .attributed(attributes, declaration))
        }
        return .attributed(attributes, self)
    }
}

extension Array where Element == Declaration {

    /// Returns the declarations with the provided macros attached to the last one.
    ///
    /// Translating a component returns any inline types first, followed by the type of the component itself.
    /// - Parameter macros: The macros to attach.
    /// - Returns: The declarations.
    func attachingToLast(_ macros: [AttachedMacro]) -> Self {
        guard let last else { return self }
        return dropLast() + [last.attaching(macros)]
    }
}

extension AttributeDescription {

    /// Creates an attribute from an attached macro.
    /// - Parameter macro: The attached macro.
    init(_ macro: AttachedMacro) {
        self.init(
            name: macro.name,
            arguments: macro.arguments.map { argument in
                let value: String
                switch argument.value {
                case .literal(let literal): value = literal.swiftSource
                case .expression(let expression): value = expression
                }
                guard let label = argument.label else { return value }
                return "\(label): \(value)"
            }
        )
    }
}

extension AttachedMacro.Literal {

    /// The Swift source of the literal.
    var swiftSource: String {
        switch self {
        case .string(let value): return Self.stringLiteral(value)
        case .int(let value): return "\(value)"
        case .double(let value):
            if value.isNaN { return "Double.nan" }
            if value.isInfinite { return value < 0 ? "-Double.infinity" : "Double.infinity" }
            return "\(value)"
        case .bool(let value): return value ? "true" : "false"
        case .nil: return "nil"
        case .array(let values): return "[\(values.map(\.swiftSource).joined(separator: ", "))]"
        case .dictionary(let values):
            if values.isEmpty { return "[:]" }
            let pairs = values.sorted { $0.key < $1.key }
                .map { "\(Self.stringLiteral($0.key)): \($0.value.swiftSource)" }
            return "[\(pairs.joined(separator: ", "))]"
        }
    }

    /// Returns a single-line Swift string literal for the provided string.
    /// - Parameter value: The string.
    /// - Returns: The quoted and escaped string literal.
    private static func stringLiteral(_ value: String) -> String {
        var result = "\""
        for scalar in value.unicodeScalars {
            switch scalar {
            case "\"": result += "\\\""
            case "\\": result += "\\\\"
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            case _ where scalar.value < 0x20: result += "\\u{\(String(scalar.value, radix: 16))}"
            default: result.unicodeScalars.append(scalar)
            }
        }
        return result + "\""
    }
}

extension TypesFileTranslator {

    /// Emits a warning for each attached macro rule that doesn't match any name in the OpenAPI document.
    /// - Parameters:
    ///   - components: The components of the OpenAPI document.
    ///   - operations: The operations of the OpenAPI document.
    /// - Throws: An error if the diagnostics collector throws.
    func emitUnmatchedAttachedMacroRuleDiagnostics(
        components: OpenAPI.Components,
        operations: [OperationDescription]
    ) throws {
        let attachedMacros = config.attachedMacros
        let ruleGroups: [(path: String, patterns: [String?], names: [String])] = [
            (
                "components.schemas", attachedMacros.components.schemas.map(\.filter),
                components.schemas.keys.map(\.rawValue)
            ),
            (
                "components.parameters", attachedMacros.components.parameters.map(\.filter),
                components.parameters.keys.map(\.rawValue)
            ),
            (
                "components.requestBodies", attachedMacros.components.requestBodies.map(\.filter),
                components.requestBodies.keys.map(\.rawValue)
            ),
            (
                "components.responses", attachedMacros.components.responses.map(\.filter),
                components.responses.keys.map(\.rawValue)
            ),
            (
                "components.headers", attachedMacros.components.headers.map(\.filter),
                components.headers.keys.map(\.rawValue)
            ), ("operations", attachedMacros.operations.map(\.filter), operations.map(\.operationID)),
        ]
        for (path, patterns, names) in ruleGroups {
            for pattern in patterns where !names.contains(where: { AttachedMacros.matches(pattern, $0) }) {
                guard let pattern else {
                    try diagnostics.emit(
                        .warning(
                            message: "The attached macros rule without a filter in '\(path)' doesn't match anything.",
                            context: ["path": path]
                        )
                    )
                    continue
                }
                try diagnostics.emit(
                    .warning(
                        message:
                            "The attached macros rule with filter '\(pattern)' in '\(path)' doesn't match anything.",
                        context: ["path": path, "filter": pattern]
                    )
                )
            }
        }
    }
}
