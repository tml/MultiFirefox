import XCTest
@testable import MultiFirefox

final class FirefoxManagerTests: XCTestCase {

    func testParseProfilesExtractsNames() {
        let ini = """
        [Install]
        Default=Profiles/xyz.default
        [Profile0]
        Name=default
        IsRelative=1
        Path=Profiles/xyz.default
        [Profile1]
        Name=Work
        IsRelative=1
        Path=Profiles/abc.work
        """
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
