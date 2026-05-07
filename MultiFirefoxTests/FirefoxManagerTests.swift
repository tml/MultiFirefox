import XCTest
@testable import MultiFirefox

final class FirefoxManagerTests: XCTestCase {

    func testParseProfilesExtractsNames() {
        let ini = "[Install]\nDefault=Profiles/xyz.default\n[Profile0]\nName=default\nIsRelative=1\nPath=Profiles/xyz.default\n[Profile1]\nName=Work\nIsRelative=1\nPath=Profiles/abc.work"
        XCTAssertEqual(FirefoxManager.parseProfiles(from: ini), ["default", "Work"])
    }

    func testParseProfilesPutsDefaultFirst() {
        let ini = "[Profile0]\nName=Work\n[Profile1]\nName=default"
        XCTAssertEqual(FirefoxManager.parseProfiles(from: ini).first, "default")
    }

    func testParseProfilesSortsNonDefaultAlphabetically() {
        let ini = "[Profile0]\nName=Zebra\n[Profile1]\nName=Alpha\n[Profile2]\nName=default"
        XCTAssertEqual(FirefoxManager.parseProfiles(from: ini), ["default", "Alpha", "Zebra"])
    }

    func testParseProfilesReturnsEmptyForEmptyInput() {
        XCTAssertEqual(FirefoxManager.parseProfiles(from: ""), [])
    }
}
