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
import Foundation

/// Macros to attach to generated declarations.
public struct AttachedMacros: Sendable, Equatable {

    /// Rules for declarations generated from the components section.
    public var components: Components

    /// Rules for declarations generated for each operation.
    public var operations: [OperationRule]

    /// Macros attached to the `APIProtocol` protocol.
    public var apiProtocol: [AttachedMacro]

    /// Macros attached to the `Client` struct.
    public var client: [AttachedMacro]

    /// Macros attached to the `registerHandlers` method.
    public var server: [AttachedMacro]

    /// Creates a new instance.
    /// - Parameters:
    ///   - components: Rules for declarations generated from the components section.
    ///   - operations: Rules for declarations generated for each operation.
    ///   - apiProtocol: Macros attached to the `APIProtocol` protocol.
    ///   - client: Macros attached to the `Client` struct.
    ///   - server: Macros attached to the `registerHandlers` method.
    public init(
        components: Components = .init(),
        operations: [OperationRule] = [],
        apiProtocol: [AttachedMacro] = [],
        client: [AttachedMacro] = [],
        server: [AttachedMacro] = []
    ) {
        self.components = components
        self.operations = operations
        self.apiProtocol = apiProtocol
        self.client = client
        self.server = server
    }

    /// Rules for declarations generated from the components section.
    public struct Components: Sendable, Equatable {

        /// Rules for `Components.Schemas`.
        public var schemas: [ComponentRule]

        /// Rules for `Components.Parameters`.
        public var parameters: [ComponentRule]

        /// Rules for `Components.RequestBodies`.
        public var requestBodies: [ComponentRule]

        /// Rules for `Components.Responses`.
        public var responses: [ComponentRule]

        /// Rules for `Components.Headers`.
        public var headers: [ComponentRule]

        /// Creates a new instance.
        /// - Parameters:
        ///   - schemas: Rules for `Components.Schemas`.
        ///   - parameters: Rules for `Components.Parameters`.
        ///   - requestBodies: Rules for `Components.RequestBodies`.
        ///   - responses: Rules for `Components.Responses`.
        ///   - headers: Rules for `Components.Headers`.
        public init(
            schemas: [ComponentRule] = [],
            parameters: [ComponentRule] = [],
            requestBodies: [ComponentRule] = [],
            responses: [ComponentRule] = [],
            headers: [ComponentRule] = []
        ) {
            self.schemas = schemas
            self.parameters = parameters
            self.requestBodies = requestBodies
            self.responses = responses
            self.headers = headers
        }
    }

    /// A rule that attaches macros to the components whose OpenAPI name matches a regular expression.
    public struct ComponentRule: Sendable, Equatable {

        /// A regular expression matched against the OpenAPI name of the component, or `nil` to match all components.
        public var filter: String?

        /// Macros attached to the matched components.
        public var macros: [AttachedMacro]

        /// Creates a new instance.
        /// - Parameters:
        ///   - filter: A regular expression matched against the OpenAPI name of the component,
        ///     or `nil` to match all components.
        ///   - macros: Macros attached to the matched components.
        public init(filter: String? = nil, macros: [AttachedMacro]) {
            self.filter = filter
            self.macros = macros
        }
    }

    /// A rule that attaches macros to the declarations of operations whose identifier matches a regular expression.
    public struct OperationRule: Sendable, Equatable {

        /// A regular expression matched against the operation identifier, or `nil` to match all operations.
        public var filter: String?

        /// Macros attached to the `Operations.<Op>` namespace.
        public var operation: [AttachedMacro]

        /// Macros attached to `Operations.<Op>.Input`.
        public var input: [AttachedMacro]

        /// Macros attached to `Operations.<Op>.Output`.
        public var output: [AttachedMacro]

        /// Macros attached to the `APIProtocol` requirement of the operation.
        public var protocolMethod: [AttachedMacro]

        /// Macros attached to the `Client` method of the operation.
        public var clientMethod: [AttachedMacro]

        /// Creates a new instance.
        /// - Parameters:
        ///   - filter: A regular expression matched against the operation identifier,
        ///     or `nil` to match all operations.
        ///   - operation: Macros attached to the `Operations.<Op>` namespace.
        ///   - input: Macros attached to `Operations.<Op>.Input`.
        ///   - output: Macros attached to `Operations.<Op>.Output`.
        ///   - protocolMethod: Macros attached to the `APIProtocol` requirement of the operation.
        ///   - clientMethod: Macros attached to the `Client` method of the operation.
        public init(
            filter: String? = nil,
            operation: [AttachedMacro] = [],
            input: [AttachedMacro] = [],
            output: [AttachedMacro] = [],
            protocolMethod: [AttachedMacro] = [],
            clientMethod: [AttachedMacro] = []
        ) {
            self.filter = filter
            self.operation = operation
            self.input = input
            self.output = output
            self.protocolMethod = protocolMethod
            self.clientMethod = clientMethod
        }
    }
}

/// A macro, with optional arguments, attached to a generated declaration.
public struct AttachedMacro: Sendable, Equatable {

    /// The name of the macro, without the leading `@`.
    public var name: String

    /// The arguments of the macro, emitted in a parenthesized list when not empty.
    public var arguments: [Argument]

    /// Creates a new instance.
    /// - Parameters:
    ///   - name: The name of the macro, without the leading `@`.
    ///   - arguments: The arguments of the macro.
    public init(name: String, arguments: [Argument] = []) {
        self.name = name
        self.arguments = arguments
    }

    /// An argument of an attached macro.
    public struct Argument: Sendable, Equatable {

        /// The label of the argument, if any.
        public var label: String?

        /// The value of the argument.
        public var value: Value

        /// Creates a new instance.
        /// - Parameters:
        ///   - label: The label of the argument, if any.
        ///   - value: The value of the argument.
        public init(label: String? = nil, value: Value) {
            self.label = label
            self.value = value
        }
    }

    /// The value of an argument.
    public enum Value: Sendable, Equatable {

        /// A literal, converted to Swift literal syntax.
        case literal(Literal)

        /// Swift source emitted verbatim.
        case expression(String)
    }

    /// A literal value of an argument.
    public indirect enum Literal: Sendable, Equatable {

        /// A string literal.
        case string(String)

        /// An integer literal.
        case int(Int)

        /// A floating-point literal.
        case double(Double)

        /// A Boolean literal.
        case bool(Bool)

        /// The `nil` literal.
        case `nil`

        /// An array literal.
        case array([Literal])

        /// A dictionary literal with string keys.
        case dictionary([String: Literal])
    }
}

extension AttachedMacros {

    /// Returns the macros of the rules that match the provided name, in rule order and without duplicates.
    /// - Parameters:
    ///   - rules: The rules to evaluate.
    ///   - name: The OpenAPI name to match.
    /// - Returns: The matching macros.
    static func macros(in rules: [ComponentRule], matching name: String) -> [AttachedMacro] {
        uniqued(rules.filter { matches($0.filter, name) }.flatMap(\.macros))
    }

    /// Returns the macros of the operation rules that match the provided operation identifier,
    /// in rule order and without duplicates.
    /// - Parameters:
    ///   - target: The target within each matching rule.
    ///   - operationID: The operation identifier to match.
    /// - Returns: The matching macros.
    func macros(for target: KeyPath<OperationRule, [AttachedMacro]>, operationID: String) -> [AttachedMacro] {
        Self.uniqued(operations.filter { Self.matches($0.filter, operationID) }.flatMap { $0[keyPath: target] })
    }

    /// Returns whether the regular expression matches anywhere in the provided name.
    /// - Parameters:
    ///   - pattern: The regular expression, or `nil` to match any name.
    ///   - name: The name to match.
    /// - Returns: `true` if the pattern is `nil` or matches; `false` otherwise, including when the pattern is invalid.
    static func matches(_ pattern: String?, _ name: String) -> Bool {
        guard let pattern else { return true }
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) != nil
    }

    /// Returns the macros with duplicates removed, keeping the first occurrence.
    /// - Parameter macros: The macros.
    /// - Returns: The macros without duplicates.
    private static func uniqued(_ macros: [AttachedMacro]) -> [AttachedMacro] {
        var result: [AttachedMacro] = []
        for macro in macros where !result.contains(macro) { result.append(macro) }
        return result
    }
}

extension AttachedMacros: Codable {
    enum CodingKeys: String, CaseIterable, CodingKey {
        case components
        case operations
        case apiProtocol
        case client
        case server
    }

    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the data is invalid or contains unknown keys.
    public init(from decoder: any Decoder) throws {
        try decoder.rejectUnknownKeys(CodingKeys.self)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            components: try container.decodeIfPresent(Components.self, forKey: .components) ?? .init(),
            operations: try container.decodeIfPresent([OperationRule].self, forKey: .operations) ?? [],
            apiProtocol: try container.decodeIfPresent([AttachedMacro].self, forKey: .apiProtocol) ?? [],
            client: try container.decodeIfPresent([AttachedMacro].self, forKey: .client) ?? [],
            server: try container.decodeIfPresent([AttachedMacro].self, forKey: .server) ?? []
        )
    }
}

extension AttachedMacros.Components: Codable {
    enum CodingKeys: String, CaseIterable, CodingKey {
        case schemas
        case parameters
        case requestBodies
        case responses
        case headers
    }

    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the data is invalid or contains unknown keys.
    public init(from decoder: any Decoder) throws {
        try decoder.rejectUnknownKeys(CodingKeys.self)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        typealias Rules = [AttachedMacros.ComponentRule]
        self.init(
            schemas: try container.decodeIfPresent(Rules.self, forKey: .schemas) ?? [],
            parameters: try container.decodeIfPresent(Rules.self, forKey: .parameters) ?? [],
            requestBodies: try container.decodeIfPresent(Rules.self, forKey: .requestBodies) ?? [],
            responses: try container.decodeIfPresent(Rules.self, forKey: .responses) ?? [],
            headers: try container.decodeIfPresent(Rules.self, forKey: .headers) ?? []
        )
    }
}

extension AttachedMacros.ComponentRule: Codable {
    enum CodingKeys: String, CaseIterable, CodingKey {
        case filter
        case macros
    }

    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the data is invalid or contains unknown keys.
    public init(from decoder: any Decoder) throws {
        try decoder.rejectUnknownKeys(CodingKeys.self)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            filter: try container.decodeRegularExpressionIfPresent(forKey: .filter),
            macros: try container.decode([AttachedMacro].self, forKey: .macros)
        )
    }
}

extension AttachedMacros.OperationRule: Codable {
    enum CodingKeys: String, CaseIterable, CodingKey {
        case filter
        case operation
        case input
        case output
        case protocolMethod
        case clientMethod
    }

    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the data is invalid or contains unknown keys.
    public init(from decoder: any Decoder) throws {
        try decoder.rejectUnknownKeys(CodingKeys.self)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            filter: try container.decodeRegularExpressionIfPresent(forKey: .filter),
            operation: try container.decodeIfPresent([AttachedMacro].self, forKey: .operation) ?? [],
            input: try container.decodeIfPresent([AttachedMacro].self, forKey: .input) ?? [],
            output: try container.decodeIfPresent([AttachedMacro].self, forKey: .output) ?? [],
            protocolMethod: try container.decodeIfPresent([AttachedMacro].self, forKey: .protocolMethod) ?? [],
            clientMethod: try container.decodeIfPresent([AttachedMacro].self, forKey: .clientMethod) ?? []
        )
    }
}

extension AttachedMacro: Codable {
    enum CodingKeys: String, CaseIterable, CodingKey {
        case name
        case arguments
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// Accepts either a string with the macro name, or an object with a name and arguments.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the data is invalid or contains unknown keys.
    public init(from decoder: any Decoder) throws {
        if let name = try? decoder.singleValueContainer().decode(String.self) {
            self.init(name: try Self.validatedName(name, codingPath: decoder.codingPath))
            return
        }
        try decoder.rejectUnknownKeys(CodingKeys.self)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try Self.validatedName(
                try container.decode(String.self, forKey: .name),
                codingPath: container.codingPath + [CodingKeys.name]
            ),
            arguments: try container.decodeIfPresent([Argument].self, forKey: .arguments) ?? []
        )
    }

    /// Encodes this value into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        if !arguments.isEmpty { try container.encode(arguments, forKey: .arguments) }
    }

    /// Returns the name if it's valid.
    /// - Parameters:
    ///   - name: The macro name.
    ///   - codingPath: The coding path used in the error.
    /// - Returns: The validated name.
    /// - Throws: An error if the name is empty or starts with `@`.
    private static func validatedName(_ name: String, codingPath: [any CodingKey]) throws -> String {
        guard !name.isEmpty, !name.hasPrefix("@") else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: codingPath,
                    debugDescription:
                        "Invalid macro name '\(name)'. Provide the name without the leading '@', for example 'Mockable'."
                )
            )
        }
        return name
    }
}

extension AttachedMacro.Argument: Codable {
    enum CodingKeys: String, CaseIterable, CodingKey {
        case label
        case value
        case expression
    }

    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the data is invalid, contains unknown keys, or doesn't contain exactly one
    ///   of `value` or `expression`.
    public init(from decoder: any Decoder) throws {
        try decoder.rejectUnknownKeys(CodingKeys.self)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let label = try container.decodeIfPresent(String.self, forKey: .label)
        switch (container.contains(.value), container.contains(.expression)) {
        case (true, false):
            self.init(label: label, value: .literal(try container.decode(AttachedMacro.Literal.self, forKey: .value)))
        case (false, true):
            self.init(label: label, value: .expression(try container.decode(String.self, forKey: .expression)))
        default:
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "A macro argument must have exactly one of 'value' or 'expression'."
                )
            )
        }
    }

    /// Encodes this value into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(label, forKey: .label)
        switch value {
        case .literal(let literal): try container.encode(literal, forKey: .value)
        case .expression(let expression): try container.encode(expression, forKey: .expression)
        }
    }
}

extension AttachedMacro.Literal: Codable {

    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the value isn't a scalar, sequence, or mapping.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .nil
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([Self].self) {
            self = .array(value)
        } else {
            self = .dictionary(try container.decode([String: Self].self))
        }
    }

    /// Encodes this value into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .nil: try container.encodeNil()
        case .array(let value): try container.encode(value)
        case .dictionary(let value): try container.encode(value)
        }
    }
}

/// A coding key that accepts any string.
private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

extension Decoder {

    /// Throws an error if the keyed container contains a key not in the provided coding keys.
    /// - Parameter keys: The allowed coding keys.
    /// - Throws: An error describing the first unknown key.
    fileprivate func rejectUnknownKeys<Keys: CodingKey & CaseIterable>(_ keys: Keys.Type) throws {
        let allowed = Set(Keys.allCases.map(\.stringValue))
        let container = try container(keyedBy: AnyCodingKey.self)
        for key in container.allKeys where !allowed.contains(key.stringValue) {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: codingPath + [key],
                    debugDescription:
                        "Unknown key '\(key.stringValue)'. Allowed keys: \(allowed.sorted().joined(separator: ", "))."
                )
            )
        }
    }
}

extension KeyedDecodingContainer {

    /// Decodes a string, if present, and checks that it's a valid regular expression.
    /// - Parameter key: The key to decode.
    /// - Returns: The regular expression pattern, or `nil` if the key is missing.
    /// - Throws: An error if the value isn't a valid regular expression.
    fileprivate func decodeRegularExpressionIfPresent(forKey key: Key) throws -> String? {
        guard let pattern = try decodeIfPresent(String.self, forKey: key) else { return nil }
        do { _ = try NSRegularExpression(pattern: pattern) } catch {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Invalid regular expression '\(pattern)': \(error)"
            )
        }
        return pattern
    }
}
