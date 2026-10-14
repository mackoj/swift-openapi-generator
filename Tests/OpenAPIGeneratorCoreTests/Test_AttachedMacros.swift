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
import XCTest
import OpenAPIKit
import Yams
@testable import _OpenAPIGeneratorCore

final class Test_AttachedMacros: Test_Core {

    func testDecodingEmpty() throws {
        XCTAssertEqual(try YAMLDecoder().decode(AttachedMacros.self, from: "{}"), AttachedMacros())
        XCTAssertEqual(
            try YAMLDecoder().decode(AttachedMacros.self, from: "components: {}"),
            AttachedMacros(components: .init())
        )
    }

    func testDecodingAllTargets() throws {
        let attachedMacros = try YAMLDecoder()
            .decode(
                AttachedMacros.self,
                from: """
                    components:
                      schemas:
                        - filter: "^Schema$"
                          macros: [Schema]
                      parameters:
                        - filter: "^Parameter$"
                          macros: [Parameter]
                      requestBodies:
                        - filter: "^RequestBody$"
                          macros: [RequestBody]
                      responses:
                        - filter: "^Response$"
                          macros: [Response]
                      headers:
                        - filter: "^Header$"
                          macros: [Header]
                    operations:
                      - filter: "^createPet$"
                        operation: [Operation]
                        input: [Input]
                        output: [Output]
                        protocolMethod: [ProtocolMethod]
                        clientMethod: [ClientMethod]
                      - filter: "^listPets$"
                    apiProtocol: [APIProtocol]
                    client: [Client]
                    server: [Server]
                    """
            )
        XCTAssertEqual(
            attachedMacros,
            AttachedMacros(
                components: .init(
                    schemas: [.init(filter: "^Schema$", macros: [.init(name: "Schema")])],
                    parameters: [.init(filter: "^Parameter$", macros: [.init(name: "Parameter")])],
                    requestBodies: [.init(filter: "^RequestBody$", macros: [.init(name: "RequestBody")])],
                    responses: [.init(filter: "^Response$", macros: [.init(name: "Response")])],
                    headers: [.init(filter: "^Header$", macros: [.init(name: "Header")])]
                ),
                operations: [
                    .init(
                        filter: "^createPet$",
                        operation: [.init(name: "Operation")],
                        input: [.init(name: "Input")],
                        output: [.init(name: "Output")],
                        protocolMethod: [.init(name: "ProtocolMethod")],
                        clientMethod: [.init(name: "ClientMethod")]
                    ), .init(filter: "^listPets$"),
                ],
                apiProtocol: [.init(name: "APIProtocol")],
                client: [.init(name: "Client")],
                server: [.init(name: "Server")]
            )
        )
    }

    func testDecodingRulesWithoutFilter() throws {
        let attachedMacros = try YAMLDecoder()
            .decode(
                AttachedMacros.self,
                from: """
                    components:
                      schemas:
                        - macros: [Schema]
                    operations:
                      - input: [Input]
                    """
            )
        XCTAssertEqual(
            attachedMacros,
            AttachedMacros(
                components: .init(schemas: [.init(macros: [.init(name: "Schema")])]),
                operations: [.init(input: [.init(name: "Input")])]
            )
        )
    }

    func testDecodingMacros() throws {
        let macros = try YAMLDecoder()
            .decode(
                [AttachedMacro].self,
                from: """
                    - Mockable
                    - name: Mockable
                    - name: Module.Macro
                      arguments: []
                    - name: DependencyClientWrapper
                      arguments:
                        - label: name
                          value: PetStoreClient
                        - label: mode
                          expression: .live
                        - expression: Foo.self
                    """
            )
        XCTAssertEqual(
            macros,
            [
                .init(name: "Mockable"), .init(name: "Mockable"), .init(name: "Module.Macro"),
                .init(
                    name: "DependencyClientWrapper",
                    arguments: [
                        .init(label: "name", value: .literal(.string("PetStoreClient"))),
                        .init(label: "mode", value: .expression(".live")), .init(value: .expression("Foo.self")),
                    ]
                ),
            ]
        )
    }

    func testDecodingLiterals() throws {
        let cases: [(String, AttachedMacro.Literal)] = [
            ("PetStoreClient", .string("PetStoreClient")), ("'3'", .string("3")), ("\"true\"", .string("true")),
            ("''", .string("")), ("3", .int(3)), ("-3", .int(-3)), ("0.5", .double(0.5)), ("-1.5", .double(-1.5)),
            ("true", .bool(true)), ("false", .bool(false)), ("null", .nil), ("[]", .array([])),
            ("[a, 1, [true]]", .array([.string("a"), .int(1), .array([.bool(true)])])), ("{}", .dictionary([:])),
            ("{max: 3, nested: {list: [a]}}", .dictionary(["max": .int(3), "nested": .dictionary(["list": .array([.string("a")])])])),
        ]
        for (yaml, expected) in cases {
            let decoded = try YAMLDecoder().decode([String: AttachedMacro.Literal].self, from: "value: \(yaml)")
            XCTAssertEqual(decoded["value"], expected, yaml)
        }
    }

    func testDecodingErrors() throws {
        let invalidConfigs = [
            // Unknown keys at every level.
            "clients: [A]", "components: {examples: []}", "components: {schemas: [{filter: A, macro: [A]}]}",
            "operations: [{filter: A, ouput: [A]}]", "apiProtocol: [{name: A, argument: []}]",
            "apiProtocol: [{name: A, arguments: [{lable: x, value: 1}]}]",
            // Missing required keys.
            "components: {schemas: [{filter: A}]}", "apiProtocol: [{arguments: []}]",
            // Invalid regular expressions.
            "components: {schemas: [{filter: '(', macros: [A]}]}", "operations: [{filter: '[', input: [A]}]",
            // Invalid macro names.
            "apiProtocol: ['@Mockable']", "apiProtocol: [{name: '@Mockable'}]", "apiProtocol: ['']",
            "apiProtocol: [{name: [A]}]",
            // Arguments without exactly one of value or expression.
            "apiProtocol: [{name: A, arguments: [{label: x}]}]",
            "apiProtocol: [{name: A, arguments: [{value: 1, expression: '2'}]}]",
            // Wrong types.
            "apiProtocol: A", "operations: {filter: A}",
        ]
        for yaml in invalidConfigs {
            XCTAssertThrowsError(try YAMLDecoder().decode(AttachedMacros.self, from: yaml), yaml)
        }
    }

    func testDecodingErrorMessages() throws {
        func message(_ yaml: String) -> String? {
            do {
                _ = try YAMLDecoder().decode(AttachedMacros.self, from: yaml)
                return nil
            } catch DecodingError.dataCorrupted(let context) { return context.debugDescription } catch {
                return "\(error)"
            }
        }
        XCTAssertEqual(
            message("operations: [{filter: A, ouput: [A]}]"),
            "Unknown key 'ouput'. Allowed keys: clientMethod, filter, input, operation, output, protocolMethod."
        )
        XCTAssertEqual(
            message("apiProtocol: ['@Mockable']"),
            "Invalid macro name '@Mockable'. Provide the name without the leading '@', for example 'Mockable'."
        )
        XCTAssertEqual(
            message("apiProtocol: [{name: A, arguments: [{label: x}]}]"),
            "A macro argument must have exactly one of 'value' or 'expression'."
        )
        XCTAssertEqual(
            message("components: {schemas: [{filter: '(', macros: [A]}]}")?.hasPrefix("Invalid regular expression '('"),
            true
        )
    }

    func testEncodingRoundTrip() throws {
        let attachedMacros = AttachedMacros(
            components: .init(schemas: [.init(filter: ".*", macros: [.init(name: "A")])]),
            operations: [.init(filter: "^createPet$", input: [.init(name: "B")])],
            apiProtocol: [
                .init(
                    name: "C",
                    arguments: [
                        .init(label: "name", value: .literal(.string("x"))), .init(value: .expression(".live")),
                        .init(value: .literal(.array([.int(1), .double(0.5), .bool(true), .nil]))),
                        .init(value: .literal(.dictionary(["k": .string("v")]))),
                    ]
                )
            ]
        )
        let encoded = try YAMLEncoder().encode(attachedMacros)
        XCTAssertEqual(try YAMLDecoder().decode(AttachedMacros.self, from: encoded), attachedMacros)
    }

    func testMatching() {
        XCTAssertTrue(AttachedMacros.matches(".*", "Pet"))
        XCTAssertTrue(AttachedMacros.matches(".*", ""))
        XCTAssertTrue(AttachedMacros.matches("Pet", "PetOwner"))
        XCTAssertTrue(AttachedMacros.matches("Owner", "PetOwner"))
        XCTAssertFalse(AttachedMacros.matches("^Pet$", "PetOwner"))
        XCTAssertTrue(AttachedMacros.matches("^Pet$", "Pet"))
        XCTAssertFalse(AttachedMacros.matches("^pet$", "Pet"))
        XCTAssertTrue(AttachedMacros.matches("(?i)^pet$", "Pet"))
        XCTAssertTrue(AttachedMacros.matches("^pet-store$", "pet-store"))
        XCTAssertTrue(AttachedMacros.matches(#"^get/pets/\{petId\}$"#, "get/pets/{petId}"))
        XCTAssertTrue(AttachedMacros.matches("^Pét$", "Pét"))
        XCTAssertFalse(AttachedMacros.matches("(", "("))
        XCTAssertTrue(AttachedMacros.matches(nil, "Pet"))
        XCTAssertTrue(AttachedMacros.matches(nil, ""))
    }

    func testComponentRules() {
        let rules: [AttachedMacros.ComponentRule] = [
            .init(filter: ".*", macros: [.init(name: "A")]), .init(filter: "^Pet$", macros: [.init(name: "B")]),
            .init(filter: "Pet", macros: [.init(name: "A"), .init(name: "C")]), .init(macros: [.init(name: "D")]),
        ]
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "Pet").map(\.name), ["A", "B", "C", "D"])
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "PetOwner").map(\.name), ["A", "C", "D"])
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "Owner").map(\.name), ["A", "D"])
        XCTAssertEqual(AttachedMacros.macros(in: [], matching: "Pet"), [])
    }

    func testDuplicateMacros() {
        let a = AttachedMacro(name: "A")
        let aWithArgument = AttachedMacro(name: "A", arguments: [.init(value: .literal(.int(1)))])
        let aWithOtherArgument = AttachedMacro(name: "A", arguments: [.init(value: .literal(.int(2)))])
        let rules: [AttachedMacros.ComponentRule] = [
            .init(filter: ".*", macros: [a, aWithArgument, a]),
            .init(filter: ".*", macros: [aWithOtherArgument, aWithArgument]),
        ]
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "Pet"), [a, aWithArgument, aWithOtherArgument])
    }

    func testOperationRules() {
        let attachedMacros = AttachedMacros(operations: [
            .init(
                filter: "^create",
                operation: [.init(name: "Operation")],
                input: [.init(name: "Input")],
                output: [.init(name: "Output")],
                protocolMethod: [.init(name: "ProtocolMethod")],
                clientMethod: [.init(name: "ClientMethod")]
            ), .init(filter: "Pet$", input: [.init(name: "Input"), .init(name: "PetInput")]),
            .init(output: [.init(name: "AllOutput")]),
        ])
        XCTAssertEqual(attachedMacros.macros(for: \.operation, operationID: "createPet").map(\.name), ["Operation"])
        XCTAssertEqual(attachedMacros.macros(for: \.input, operationID: "createPet").map(\.name), ["Input", "PetInput"])
        XCTAssertEqual(
            attachedMacros.macros(for: \.output, operationID: "createPet").map(\.name),
            ["Output", "AllOutput"]
        )
        XCTAssertEqual(
            attachedMacros.macros(for: \.protocolMethod, operationID: "createPet").map(\.name),
            ["ProtocolMethod"]
        )
        XCTAssertEqual(attachedMacros.macros(for: \.clientMethod, operationID: "createPet").map(\.name), ["ClientMethod"])
        XCTAssertEqual(attachedMacros.macros(for: \.input, operationID: "getPet").map(\.name), ["Input", "PetInput"])
        XCTAssertEqual(attachedMacros.macros(for: \.output, operationID: "getPet").map(\.name), ["AllOutput"])
        XCTAssertEqual(attachedMacros.macros(for: \.input, operationID: "listPets").map(\.name), [])
    }

    func testAttributeFromMacro() {
        XCTAssertEqual(AttributeDescription(AttachedMacro(name: "Mockable")), .init(name: "Mockable"))
        XCTAssertEqual(
            AttributeDescription(
                AttachedMacro(
                    name: "Foo",
                    arguments: [
                        .init(label: "name", value: .literal(.string("Pet"))), .init(value: .literal(.int(1))),
                        .init(label: "mode", value: .expression(".live")), .init(value: .expression("Foo.self")),
                    ]
                )
            ),
            .init(name: "Foo", arguments: [#"name: "Pet""#, "1", "mode: .live", "Foo.self"])
        )
    }

    func testLiteralSwiftSource() {
        let cases: [(AttachedMacro.Literal, String)] = [
            (.string("Pet"), #""Pet""#), (.string(""), #""""#), (.string(#"a "b" \c"#), #""a \"b\" \\c""#),
            (.string("a\nb\r\tc"), #""a\nb\r\tc""#), (.string("\u{1}"), #""\u{1}""#), (.string("Pét 🐶"), #""Pét 🐶""#),
            (.int(0), "0"), (.int(-3), "-3"), (.double(0.5), "0.5"), (.double(-1.5), "-1.5"), (.double(1), "1.0"),
            (.double(.nan), "Double.nan"), (.double(.infinity), "Double.infinity"),
            (.double(-.infinity), "-Double.infinity"), (.bool(true), "true"), (.bool(false), "false"), (.nil, "nil"),
            (.array([]), "[]"), (.array([.string("a"), .int(1), .array([.nil])]), #"["a", 1, [nil]]"#),
            (.dictionary([:]), "[:]"), (.dictionary(["b": .int(2), "a": .dictionary(["c": .bool(true)])]), #"["a": ["c": true], "b": 2]"#),
            (.dictionary(["\"": .int(1)]), #"["\"": 1]"#),
        ]
        for (literal, expected) in cases { XCTAssertEqual(literal.swiftSource, expected) }
    }

    func testAttaching() {
        let declaration = Declaration.struct(.init(name: "Pet"))
        XCTAssertEqual(declaration.attaching([]), declaration)
        XCTAssertEqual(declaration.attaching([.init(name: "A")]), .attributed([.init(name: "A")], declaration))
        XCTAssertEqual(
            Declaration.commentable(.doc("A pet."), declaration).attaching([.init(name: "A"), .init(name: "B")]),
            .commentable(.doc("A pet."), .attributed([.init(name: "A"), .init(name: "B")], declaration))
        )
        XCTAssertEqual(
            Declaration.commentable(.doc("A pet."), .deprecated(.init(), declaration)).attaching([.init(name: "A")]),
            .commentable(.doc("A pet."), .attributed([.init(name: "A")], .deprecated(.init(), declaration)))
        )
    }

    func testAttachingToLast() {
        let inline = Declaration.enum(.init(name: "Inline"))
        let declaration = Declaration.struct(.init(name: "Pet"))
        XCTAssertEqual([Declaration]().attachingToLast([.init(name: "A")]), [])
        XCTAssertEqual([inline, declaration].attachingToLast([]), [inline, declaration])
        XCTAssertEqual(
            [inline, declaration].attachingToLast([.init(name: "A")]),
            [inline, .attributed([.init(name: "A")], declaration)]
        )
    }

    func testAttributedDeclarationPassesThrough() {
        var declaration = Declaration.attributed([.init(name: "A")], .struct(.init(name: "Pet")))
        XCTAssertEqual(declaration.name, "Pet")
        XCTAssertTrue(declaration.isBoxable)
        XCTAssertNil(declaration.accessModifier)
        declaration.accessModifier = .public
        XCTAssertEqual(declaration, .attributed([.init(name: "A")], .struct(.init(accessModifier: .public, name: "Pet"))))
    }

    func testUnmatchedRuleWarnings() throws {
        let rule = { (filter: String) in AttachedMacros.ComponentRule(filter: filter, macros: [.init(name: "A")]) }
        let collector = AccumulatingDiagnosticCollector()
        let translator = TypesFileTranslator(
            config: Config(
                mode: .types,
                access: .public,
                namingStrategy: .defensive,
                attachedMacros: .init(
                    components: .init(
                        schemas: [rule("^Pet$"), rule("^Owner$")],
                        parameters: [rule("^limit$"), rule("^offset$")],
                        requestBodies: [rule("^Body$"), rule("^OtherBody$")],
                        responses: [rule("^Ok$"), rule("^NotFound$")],
                        headers: [rule("^Trace$"), rule("^Rate$")]
                    ),
                    operations: [.init(filter: "^createPet$"), .init(filter: "^deletePet$")]
                )
            ),
            diagnostics: collector,
            components: .noComponents
        )
        let paths = try YAMLDecoder()
            .decode(
                OpenAPI.PathItem.Map.self,
                from: """
                    /pets:
                      post:
                        operationId: createPet
                        responses:
                          '204':
                            description: No content
                    """
            )
        let components = try YAMLDecoder()
            .decode(
                OpenAPI.Components.self,
                from: """
                    schemas:
                      Pet:
                        type: string
                    parameters:
                      limit:
                        name: limit
                        in: query
                        schema:
                          type: integer
                    requestBodies:
                      Body:
                        content:
                          application/json:
                            schema:
                              type: string
                    responses:
                      Ok:
                        description: Ok
                    headers:
                      Trace:
                        schema:
                          type: string
                    """
            )
        try translator.emitUnmatchedAttachedMacroRuleDiagnostics(
            components: components,
            operations: OperationDescription.all(from: paths, in: components, context: translator.context)
        )
        XCTAssertEqual(
            collector.diagnostics.map(\.description),
            [
                "warning: The attached macros rule with filter '^Owner$' in 'components.schemas' doesn't match anything. [context: filter=^Owner$, path=components.schemas]",
                "warning: The attached macros rule with filter '^offset$' in 'components.parameters' doesn't match anything. [context: filter=^offset$, path=components.parameters]",
                "warning: The attached macros rule with filter '^OtherBody$' in 'components.requestBodies' doesn't match anything. [context: filter=^OtherBody$, path=components.requestBodies]",
                "warning: The attached macros rule with filter '^NotFound$' in 'components.responses' doesn't match anything. [context: filter=^NotFound$, path=components.responses]",
                "warning: The attached macros rule with filter '^Rate$' in 'components.headers' doesn't match anything. [context: filter=^Rate$, path=components.headers]",
                "warning: The attached macros rule with filter '^deletePet$' in 'operations' doesn't match anything. [context: filter=^deletePet$, path=operations]",
            ]
        )
    }

    func testUnmatchedRuleWithoutFilterWarnings() throws {
        let collector = AccumulatingDiagnosticCollector()
        let translator = TypesFileTranslator(
            config: Config(
                mode: .types,
                access: .public,
                namingStrategy: .defensive,
                attachedMacros: .init(
                    components: .init(schemas: [.init(macros: [.init(name: "A")])]),
                    operations: [.init(input: [.init(name: "A")])]
                )
            ),
            diagnostics: collector,
            components: .noComponents
        )
        try translator.emitUnmatchedAttachedMacroRuleDiagnostics(components: .noComponents, operations: [])
        XCTAssertEqual(
            collector.diagnostics.map(\.description),
            [
                "warning: The attached macros rule without a filter in 'components.schemas' doesn't match anything. [context: path=components.schemas]",
                "warning: The attached macros rule without a filter in 'operations' doesn't match anything. [context: path=operations]",
            ]
        )
    }

    func testNoWarningsWithoutAttachedMacros() throws {
        let collector = AccumulatingDiagnosticCollector()
        let translator = TypesFileTranslator(
            config: Config(mode: .types, access: .public, namingStrategy: .defensive),
            diagnostics: collector,
            components: .noComponents
        )
        try translator.emitUnmatchedAttachedMacroRuleDiagnostics(components: .noComponents, operations: [])
        XCTAssertEqual(collector.diagnostics.map(\.description), [])
    }
}
