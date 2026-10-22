import XCTest

final class RegisterUITests: XCTestCase {
    func testCheckoutFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.buttons["register"].tap()
        selectProduct("アイテム1", in: app)
        selectProduct("アイテム4", in: app)
        selectProduct("りんご", in: app)
        selectProduct("パンツ", in: app)
        XCTAssertEqual(app.staticTexts["total"].label, "合計  10,644円")
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "対面レジ"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.buttons["checkout"].tap()
        assertConfirmVisible(app)
        XCTAssertTrue(app.staticTexts["received"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["received"].label, "11,000円")
        XCTAssertEqual(app.staticTexts["change"].label, "釣り銭  356円")
        app.buttons["key-2"].tap(); app.buttons["key-0"].tap(); app.buttons["key-00"].tap(); app.buttons["key-0"].tap()
        XCTAssertEqual(app.staticTexts["change"].label, "釣り銭  9,356円")
        let payment = XCTAttachment(screenshot: app.screenshot()); payment.name = "釣り銭計算"; payment.lifetime = .keepAlways; add(payment)
        app.buttons["confirm-payment"].tap()
        app.buttons["次の会計"].tap()
        XCTAssertEqual(app.staticTexts["total"].label, "合計  0円")
        app.buttons["終了"].tap(); app.buttons["report"].tap()
        XCTAssertTrue(app.buttons["この日の売上をCSV書き出し"].isEnabled)
        let report = XCTAttachment(screenshot: app.screenshot()); report.name = "日報"; report.lifetime = .keepAlways; add(report)
    }
    private func selectProduct(_ name: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons["product-\(name)"]
        let list = app.scrollViews["product-list"]
        for _ in 0..<8 {
            if button.exists && button.isHittable { break }
            list.swipeUp()
        }
        XCTAssertTrue(button.isHittable, "商品をスクロールして選択できる", file: file, line: line)
        button.tap()
    }
    private func assertConfirmVisible(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let confirm = app.buttons["confirm-payment"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertTrue(confirm.isHittable, "スクロールせず確定ボタンを押せる", file: file, line: line)
        let panel = app.windows.firstMatch
        XCTAssertTrue(panel.exists, file: file, line: line)
        XCTAssertGreaterThanOrEqual(confirm.frame.minY, panel.frame.minY, file: file, line: line)
        XCTAssertLessThanOrEqual(confirm.frame.maxY, panel.frame.maxY, file: file, line: line)
    }
    func testFirstAndRepeatedCheckoutPresentations() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.buttons["register"].tap()
        app.buttons["product-アイテム1"].tap()
        app.buttons["checkout"].tap()
        assertConfirmVisible(app)
        app.buttons["閉じる"].tap()
        app.buttons["釣り銭計算"].tap()
        XCTAssertTrue(app.buttons["key-7"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["confirm-payment"].exists)
        app.buttons["閉じる"].tap()
        app.buttons["checkout"].tap()
        assertConfirmVisible(app)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "確定ボタン固定表示"; shot.lifetime = .keepAlways; add(shot)
        app.buttons["confirm-payment"].tap()
        app.buttons["次の会計"].tap()
        app.buttons["product-アイテム1"].tap()
        app.buttons["checkout"].tap()
        assertConfirmVisible(app)
    }

    func testPaymentAmountSurvivesRotation() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.buttons["register"].tap()
        app.buttons["product-アイテム1"].tap()
        app.buttons["checkout"].tap()
        assertConfirmVisible(app)
        app.buttons["key-2"].tap()
        app.buttons["key-00"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        let confirm = app.buttons["confirm-payment"]
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: confirm)
        XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 5), .completed)
        assertConfirmVisible(app)
        XCTAssertEqual(app.staticTexts["received"].label, "200円")
        XCTAssertEqual(app.staticTexts["change"].label, "釣り銭  100円")
        app.buttons["confirm-payment"].tap()
        app.buttons["次の会計"].tap()
        XCTAssertEqual(app.staticTexts["total"].label, "合計  0円")
    }

    func testRotationKeepsCartAndPaymentVisible() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.buttons["register"].tap()
        app.buttons["product-アイテム1"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertEqual(app.staticTexts["total"].label, "合計  100円")
        for id in ["minus", "plus", "remove-selected", "clear-cart", "checkout"] {
            let button = app.buttons[id]
            let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: button)
            XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 5), .completed, "回転後も操作できる: \(id)")
        }
        app.buttons["checkout"].tap()
        assertConfirmVisible(app)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "回転時の会計確定"; shot.lifetime = .keepAlways; add(shot)
        app.buttons["閉じる"].tap()
        XCUIDevice.shared.orientation = .portrait
        XCTAssertEqual(app.staticTexts["total"].label, "合計  100円")
    }

}
