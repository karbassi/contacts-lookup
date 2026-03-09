@testable import apple_contacts_cli
import XCTest

final class ImsgModelsTests: XCTestCase {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func testDecodesKnownFields() throws {
        let jsonStr = #"{"sender":"+14155551212","text":"hello","# +
            #""participants":["+14155551212","+16505551234"],"# +
            #""isFromMe":false,"destination_caller_id":"+19522701020"}"#
        let json = Data(jsonStr.utf8)

        let msg = try decoder.decode(ImsgMessage.self, from: json)
        XCTAssertEqual(msg.sender, "+14155551212")
        XCTAssertEqual(msg.text, "hello")
        XCTAssertEqual(msg.participants, ["+14155551212", "+16505551234"])
        XCTAssertEqual(msg.isFromMe, false)
        XCTAssertEqual(msg.destinationCallerId, "+19522701020")
    }

    func testPreservesUnknownFields() throws {
        let json = Data("""
        {"sender":"+14155551212","text":"hi","chat_id":215,"id":42,"attachments":[]}
        """.utf8)

        let msg = try decoder.decode(ImsgMessage.self, from: json)
        encoder.outputFormatting = [.sortedKeys]
        let reencoded = try encoder.encode(msg)
        let reobj = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: reencoded) as? [String: Any]
        )

        XCTAssertEqual(reobj["chat_id"] as? Int, 215)
        XCTAssertEqual(reobj["id"] as? Int, 42)
        XCTAssertNotNil(reobj["attachments"])
    }

    func testRoundTrip() throws {
        let json = Data("""
        {"sender":"Jane Doe","text":"hey","date":"2026-02-28T18:00:00Z","isFromMe":false,"chat_id":1}
        """.utf8)

        let msg = try decoder.decode(ImsgMessage.self, from: json)
        encoder.outputFormatting = [.sortedKeys]
        let reencoded = try encoder.encode(msg)
        let original = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: json) as? [String: Any]
        )
        let roundtripped = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: reencoded) as? [String: Any]
        )

        XCTAssertEqual(original["sender"] as? String, roundtripped["sender"] as? String)
        XCTAssertEqual(original["text"] as? String, roundtripped["text"] as? String)
        XCTAssertEqual(original["chat_id"] as? Int, roundtripped["chat_id"] as? Int)
    }

    func testNullSenderDecodesAsNil() throws {
        let json = Data("""
        {"sender":null,"text":"hi"}
        """.utf8)

        let msg = try decoder.decode(ImsgMessage.self, from: json)
        XCTAssertNil(msg.sender)
    }
}
