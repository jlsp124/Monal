//
//  HelperToolsTest.swift
//  MonalXMPPUnitTests
//
//  Created by Matthew Fennell on 09/08/2026.
//  Copyright © 2026 monal-im.org. All rights reserved.
//

import Testing
import monalxmpp

struct HelperToolsTest {

    @Test("Reply fallback offsets round trip as Unicode scalar counts")
    func replyFallbackUnicode() throws {
        let stanza = try #require(XMPPMessage())
        let quote = "> 👨‍👩‍👧‍👦\n"
        let count = quote.unicodeScalars.count
        stanza.setReply(to: "alice@example.org", id: "original-id", fallbackLength: UInt(count))
        #expect(XMPPMessage.replyFallbackLength(for: quote + "Answer", in: stanza) == UInt(count))
    }

    @Test("Invalid fallback ranges never remove message content")
    func replyFallbackBounds() throws {
        let stanza = try #require(XMPPMessage())
        stanza.setReply(to: nil, id: "original-id", fallbackLength: 999)
        #expect(XMPPMessage.replyFallbackLength(for: "Short body", in: stanza) == 0)
        let empty = try #require(XMPPMessage())
        #expect(XMPPMessage.replyFallbackLength(for: "Body", in: empty) == 0)
    }

    @Test("Attachment replies keep their URL body intact")
    func replyWithoutTextFallback() throws {
        let stanza = try #require(XMPPMessage())
        stanza.setReply(to: nil, id: "room-stanza-id", fallbackLength: 0)
        #expect(XMPPMessage.replyFallbackLength(for: "https://example.org/file.jpg", in: stanza) == 0)
    }

    @Test("Original App Group is preferred when accessible")
    func originalAppGroup() {
        let result = MLResolveAppGroup("group.monalalpha", ["group.monalalpha.TEAM"], { _ in URL(fileURLWithPath: "/shared") })
        #expect(result == "group.monalalpha")
    }

    @Test("AltServer group is used only when the OS grants access")
    func remappedAppGroup() {
        let result = MLResolveAppGroup("group.monalalpha", ["group.other.TEAM", "group.monalalpha.TEAM"], { group in
            group == "group.monalalpha.TEAM" ? URL(fileURLWithPath: "/shared") : nil
        })
        #expect(result == "group.monalalpha.TEAM")
    }

    @Test("Unrelated metadata never selects another application's group")
    func unrelatedAppGroup() {
        let result = MLResolveAppGroup("group.monalalpha", ["group.monalalphaevil.TEAM", "group.other.TEAM"], { group in
            group == "group.monalalpha" ? nil : URL(fileURLWithPath: "/other")
        })
        #expect(result == nil)
    }

    @Test("Missing capabilities and malformed metadata fail closed")
    func inaccessibleAppGroup() {
        #expect(MLResolveAppGroup("group.monalalpha", ["group.monalalpha.TEAM"], { _ in nil }) == nil)
        #expect(MLResolveAppGroup("group.monalalpha", "not an array", { _ in nil }) == nil)
        #expect(MLResolveAppGroup("group.monalalpha", [NSNull()], { _ in nil }) == nil)
    }

    @Test("parseDateTime treats UTC XEP-0082 DateTimes as UTC", arguments: ["2026-08-09T19:51:11Z", "2026-08-09T19:51:11+00:00", "2026-08-09T19:51:11.000-00:00", "2026-08-09T19:51:11.000Z"])
    func testParseDateTimeTreatsUTCDatesAsUTC(_ dateString: String) {
        let expected = try! Date.ISO8601FormatStyle.iso8601.parse("2026-08-09T19:51:11Z")
        #expect(HelperTools.parseDateTime(dateString) == expected)
    }

    @Test("parseDateTime takes timezone offset into account when parsing non-UTC XEP-0082 DateTimes", arguments: ["2026-08-09T17:51:11-02:00", "2026-08-09T18:51:11.000-01:00", "2026-08-09T20:51:11+01:00", "2026-08-09T21:51:11.000+02:00"])
    func testParseDateTimeTakesTimezoneIntoAccount(_ dateString: String) {
        let expected = try! Date.ISO8601FormatStyle.iso8601.parse("2026-08-09T19:51:11Z")
        #expect(HelperTools.parseDateTime(dateString) == expected)
    }

}
