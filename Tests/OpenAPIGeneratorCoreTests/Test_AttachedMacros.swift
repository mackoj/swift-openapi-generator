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

    func testDecoding() throws {
        let attachedMacros = try YAMLDecoder()
            .decode(
                AttachedMacros.self,
                from: """
                    components:
                      schemas:
                        - match: ".*"
                          macros: [AllSchemas]
                    operations:
                      - match: "^createPet$"
                        output: [Out]
                        clientMethod: [ClientMethod]
                    apiProtocol:
                      - Mockable
                      - name: DependencyClientWrapper
                        arguments:
                          - label: name
                            value: PetStoreClient
                          - label: quoted
                            value: "3"
                          - value: 3
                          - value: 0.5
                          - value: true
                          - value: null
                          - value: [a, 1]
                          - value: {max: 3}
                          - label: mode
                            expression: .live
                    client: [ClientMacro]
                    server: [ServerMacro]
                    """
            )
        XCTAssertEqual(
            attachedMacros,
            AttachedMacros(
                components: .init(schemas: [.init(match: ".*", macros: [.init(name: "AllSchemas")])]),
                operations: [
                    .init(match: "^createPet$", output: [.init(name: "Out")], clientMethod: [.init(name: "ClientMethod")])
                ],
                apiProtocol: [
                    .init(name: "Mockable"),
                    .init(
                        name: "DependencyClientWrapper",
                        arguments: [
                            .init(label: "name", value: .literal(.string("PetStoreClient"))),
                            .init(label: "quoted", value: .literal(.string("3"))), .init(value: .literal(.int(3))),
                            .init(value: .literal(.double(0.5))), .init(value: .literal(.bool(true))),
                            .init(value: .literal(.nil)), .init(value: .literal(.array([.string("a"), .int(1)]))),
                            .init(value: .literal(.dictionary(["max": .int(3)]))),
                            .init(label: "mode", value: .expression(".live")),
                        ]
                    ),
                ],
                client: [.init(name: "ClientMacro")],
                server: [.init(name: "ServerMacro")]
            )
        )
    }

    func testDecodingErrors() throws {
        let invalidConfigs = [
            "apiProtocol: ['@Mockable']", "components: {schemas: [{match: '(', macros: [A]}]}",
            "components: {examples: []}", "operations: [{match: '.*', ouput: [A]}]",
            "apiProtocol: [{name: A, arguments: [{label: x}]}]",
            "apiProtocol: [{name: A, arguments: [{value: 1, expression: '2'}]}]",
        ]
        for yaml in invalidConfigs {
            XCTAssertThrowsError(try YAMLDecoder().decode(AttachedMacros.self, from: yaml), yaml)
        }
    }

    func testMatching() {
        let rules: [AttachedMacros.ComponentRule] = [
            .init(match: ".*", macros: [.init(name: "A")]), .init(match: "^Pet$", macros: [.init(name: "B")]),
            .init(match: "Pet", macros: [.init(name: "A"), .init(name: "C")]),
        ]
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "Pet").map(\.name), ["A", "B", "C"])
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "PetOwner").map(\.name), ["A", "C"])
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "pet").map(\.name), ["A"])

        let attachedMacros = AttachedMacros(operations: [
            .init(match: "^create", input: [.init(name: "In")]), .init(match: "Pet$", output: [.init(name: "Out")]),
        ])
        XCTAssertEqual(attachedMacros.macros(for: \.input, operationID: "createPet").map(\.name), ["In"])
        XCTAssertEqual(attachedMacros.macros(for: \.output, operationID: "createPet").map(\.name), ["Out"])
        XCTAssertEqual(attachedMacros.macros(for: \.input, operationID: "listPets").map(\.name), [])
    }

    func testAttributeFromMacro() {
        XCTAssertEqual(AttributeDescription(AttachedMacro(name: "Mockable")), .init(name: "Mockable"))
        XCTAssertEqual(
            AttributeDescription(
                AttachedMacro(
                    name: "Foo",
                    arguments: [
                        .init(label: "name", value: .literal(.string(#"a "b" \c"#))),
                        .init(value: .literal(.array([.int(1), .double(0.5), .bool(false), .nil]))),
                        .init(label: "map", value: .literal(.dictionary(["b": .int(2), "a": .int(1)]))),
                        .init(label: "empty", value: .literal(.dictionary([:]))),
                        .init(label: "mode", value: .expression(".live")),
                    ]
                )
            ),
            .init(
                name: "Foo",
                arguments: [
                    #"name: "a \"b\" \\c""#, "[1, 0.5, false, nil]", #"map: ["a": 1, "b": 2]"#, "empty: [:]",
                    "mode: .live",
                ]
            )
        )
    }

    func testUnmatchedRuleWarning() throws {
        let collector = AccumulatingDiagnosticCollector()
        let translator = TypesFileTranslator(
            config: Config(
                mode: .types,
                access: .public,
                namingStrategy: .defensive,
                attachedMacros: .init(
                    components: .init(schemas: [
                        .init(match: "^Pet$", macros: [.init(name: "A")]),
                        .init(match: "^Owner$", macros: [.init(name: "B")]),
                    ])
                )
            ),
            diagnostics: collector,
            components: .noComponents
        )
        try translator.emitUnmatchedAttachedMacroRuleDiagnostics(
            components: .init(schemas: ["Pet": .string]),
            operations: []
        )
        XCTAssertEqual(
            collector.diagnostics.map(\.message),
            ["The attached macros rule matching '^Owner$' in 'components.schemas' doesn't match anything."]
        )
    }
}
