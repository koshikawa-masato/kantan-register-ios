import XCTest
@testable import KantanRegister

@MainActor final class RegisterTests: XCTestCase {
    func testPhotoTotalAndQuantity() {
        let store = RegisterStore(fileURL: nil)
        for i in [0, 3, 4, 7] { store.add(store.products[i]) }
        XCTAssertEqual(store.total, 10644)
        store.changeQuantity(1)
        XCTAssertEqual(store.total, 20644)
        store.changeQuantity(-1)
        store.removeSelected()
        XCTAssertEqual(store.total, 644)
        store.clear()
        XCTAssertEqual(store.total, 0)
        XCTAssertNil(store.selected)
        XCTAssertFalse(store.checkout())
    }
    func testCashSuggestion() {
        XCTAssertEqual(suggestedCash(for: 10644), 11000)
        XCTAssertEqual(suggestedCash(for: 1000), 1000)
        XCTAssertEqual(suggestedCash(for: 333), 1000)
        XCTAssertEqual(suggestedCash(for: 0), 0)
    }
    func testPersistenceAndHistoricalPrice() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("data.json")
        let store = RegisterStore(fileURL: url)
        store.add(store.products[0]); XCTAssertTrue(store.checkout())
        store.products[0].price = 999; XCTAssertTrue(store.save())
        let reloaded = RegisterStore(fileURL: url)
        XCTAssertEqual(reloaded.products[0].price, 999)
        XCTAssertEqual(reloaded.sales.first?.total, 100)
        XCTAssertTrue(reloaded.cart.isEmpty)
    }
    func testFailedSaveKeepsCart() {
        let store = RegisterStore(fileURL: URL(fileURLWithPath: "/dev/null/data.json"))
        store.add(store.products[0])
        XCTAssertFalse(store.checkout())
        XCTAssertEqual(store.total, 100)
        XCTAssertTrue(store.sales.isEmpty)
        XCTAssertNotNil(store.saveError)
    }
    func testCSVQuotingAndTotals() {
        let line = CartLine(product: Product(name: "りんご,\"大\"", price: 100), quantity: 2)
        let csv = SalesCSV.make(sales: [Sale(lines: [line])])
        XCTAssertTrue(csv.hasPrefix("\u{FEFF}"))
        XCTAssertTrue(csv.contains("\"りんご,\"\"大\"\"\",100,2,200,200"))
        XCTAssertEqual(SalesCSV.cell("=1+1"), "\"'=1+1\"")
    }
}
