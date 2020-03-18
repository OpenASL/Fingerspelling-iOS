import XCTest

class FingerspellingUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    self.app = XCUIApplication()
    // Allows app to check if tests are running so we can mock randomness
    self.app.launchArguments.append("testing")
    self.app.launch()
    continueAfterFailure = false
  }

  func testPlayWord() {
    self.app.buttons["Press \n to begin."].tap()
    let instructions = self.app.staticTexts["Enter the word you saw."]
    self.waitForElement(instructions)
  }

  func testChangingGameMode() {
    self.app.buttons["line.horizontal.3\neyeglasses"].tap()
    self.app.buttons["Expressive"].tap()
  }

  func testCorrectAnswer() {
    self.app.typeText("the")
    self.app/*@START_MENU_TOKEN@*/ .buttons["Done"]/*[[".keyboards",".buttons[\"done\"]",".buttons[\"Done\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ .tap()
    XCTAssert(self.app.staticTexts["1"].exists)
  }

  func testOpenCloseSettings() {
    self.app.buttons["gear"].tap()
    let settingsNavigationBar = self.app.navigationBars["Settings"]
    settingsNavigationBar.buttons["Done"].tap()
  }

  private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) {
    let existsPredicate = NSPredicate(format: "exists == true")
    expectation(for: existsPredicate, evaluatedWith: element, handler: nil)
    waitForExpectations(timeout: timeout, handler: nil)
  }
}
