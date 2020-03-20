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

    let instructions = self.app.staticTexts["Enter the word you saw."]
    self.waitForElement(instructions)

    self.app.typeText("turkey")
    snapshot("02Receptive")

    self.app.buttons["Done"].tap()
    self.waitForElement(self.app.staticTexts["TURKEY"])
  }

  func testExpressive() {
    self.app.buttons["line.horizontal.3\neyeglasses"].tap()
    snapshot("04Menu")
    self.app.buttons["Expressive"].tap()

    snapshot("05Expressive")

    self.app.buttons["Reveal"].tap()

    snapshot("06Expressive")
  }

  func testOpenCloseSettings() {
    self.app.buttons["gear"].tap()
//    snapshot("07Settings")
    let settingsNavigationBar = self.app.navigationBars["Settings"]
    settingsNavigationBar.buttons["Done"].tap()
  }

  private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) {
    let existsPredicate = NSPredicate(format: "exists == true")
    expectation(for: existsPredicate, evaluatedWith: element, handler: nil)
    waitForExpectations(timeout: timeout, handler: nil)
  }
}
