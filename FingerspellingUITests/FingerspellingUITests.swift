import XCTest

class FingerspellingUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    self.app = XCUIApplication()
    // Allows app to check if tests are running so we can mock randomness
    self.app.launchArguments.append("testing")
    setupSnapshot(self.app)
    self.app.launch()
    continueAfterFailure = false
  }

  func testReceptive() {
    snapshot("00Launch")
    self.app.buttons["Press \n to begin."].tap()
    snapshot("01Receptive")

    let instructions = self.app.buttons["Enter the word you saw."]
    self.waitForElement(instructions)

    self.app.typeText("turkey")
    snapshot("02Receptive")

    self.app.buttons["Done"].tap()
    self.waitForElement(self.app.staticTexts["TURKEY"])
  }

  func testStatsReceptive() {
    self.app.buttons["28\n3"].tap()
    self.waitForElement(self.app.staticTexts["Stats (Receptive)"])
    snapshot("03Stats")
  }

  func testExpressive() {
    self.app.buttons["line.horizontal.3\neyeglasses"].tap()
    self.app.buttons["Expressive"].tap()

    snapshot("05Expressive")

    self.app.buttons["Reveal"].tap()

    snapshot("06Expressive")

    self.app.buttons["Next word"].tap()

    self.app.buttons["line.horizontal.3\nhand.raised"].tap()
    snapshot("04Menu")
  }

  func testOpenCloseSettings() {
    self.app.buttons["gear"].tap()
    let settingsNavigationBar = self.app.navigationBars["Settings"]
    settingsNavigationBar.buttons["Done"].tap()
  }

  private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) {
    let existsPredicate = NSPredicate(format: "exists == true")
    expectation(for: existsPredicate, evaluatedWith: element, handler: nil)
    waitForExpectations(timeout: timeout, handler: nil)
  }
}
