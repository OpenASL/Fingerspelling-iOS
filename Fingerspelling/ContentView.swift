import Combine
import SwiftUI

// XXX: Complicated implementation of an animated image
//   since there doesn't seem to be a better way to do this in
//   SwiftUI yet: https://stackoverflow.com/a/57749621/1157536
class LoadingTimer {
  var publisher: Timer.TimerPublisher
  private var timerCancellable: Cancellable?

  init(every: Double) {
    self.publisher = Timer.publish(every: every, on: .main, in: .default)
    self.timerCancellable = nil
  }

  func start() {
    self.timerCancellable = self.publisher.connect()
  }

  func cancel() {
    self.timerCancellable?.cancel()
  }
}

struct IconButton: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding()
      .font(.system(size: 36))
  }
}

private var words = [String]()

struct ContentView: View {
  @State private var alertIsVisible: Bool = false
  @State private var speed = 6.0
  @State private var wordFinished = true
  @State private var letterIndex = 0
  @State private var answer: String = ""
  @State private var timer: LoadingTimer = LoadingTimer(every: 0.5)
  @State private var currentWord = ""
  @State private var score = 0
  @ObservedObject private var keyboard = KeyboardResponder()

  private let numerator = 2.0
  private let minSpeed = 1.0
  private let maxSpeed = 11.0

  init() {
    if let path = Bundle.main.path(forResource: "words", ofType: "json") {
      do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        if let jsonResult = jsonResult as? [String] {
          words = jsonResult
        }
      } catch {
        print("Could not parse words.json")
      }
    }
    // XXX Setting state variable in init: https://stackoverflow.com/a/60028709/1157536
    self._currentWord = State<String>(initialValue: words.randomElement()!)
    self._speed = State<Double>(initialValue: (self.maxSpeed + self.minSpeed) / 2)
  }

  private var answerTrimmed: String {
    self.answer.trimmingCharacters(in: .whitespaces)
  }

  private var isAnswerValid: Bool {
    self.answerTrimmed.lowercased() == self.currentWord.lowercased()
  }

  private var images: [UIImage] {
    let letters = Array(self.currentWord).map { String($0).uppercased() }
    return letters.map { UIImage(named: $0)! }
  }

  private func getTimer() -> LoadingTimer {
    let every = self.numerator / max(self.speed, 1.0)
    return LoadingTimer(every: every)
  }

  private func resetTimer() {
    self.timer.cancel()
    self.timer = self.getTimer()
  }

  private func handleReplay() {
    self.letterIndex = 0
    self.wordFinished = false
  }

  private func resetWord() {
    self.letterIndex = 0
    self.wordFinished = false
  }

  private func handleNextWord() {
    self.answer = ""
    self.resetWord()
    self.currentWord = words.randomElement()!
  }

  private func handleResetSpeed() {
    self.speed = (self.maxSpeed + self.minSpeed) / 2
  }

  private func handleStop() {
    self.resetWord()
    self.wordFinished = true
    self.resetTimer()
  }

  func handleCheck() {
    self.alertIsVisible = true
    self.alertIsVisible = true
    if self.isAnswerValid {
      self.score += 1
    }
  }

  var body: some View {
    VStack {
      Spacer()
      /* Letter display */
      HStack {
        if !self.wordFinished {
          Image(uiImage: self.images[self.letterIndex])
            .resizable()
            .frame(width: 75, height: 100)
            .scaledToFit()
            .offset(x: self.letterIndex > 0 && Array(self.currentWord)[self.letterIndex - 1] == Array(self.currentWord)[self.letterIndex] ? -20 : 0)
            .onReceive(
              self.timer.publisher,
              perform: { _ in
                self.letterIndex += 1
                if self.letterIndex >= self.images.count {
                  self.wordFinished = true
                }
              }
            )
            .onAppear { self.resetTimer(); self.timer.start() }
            .onDisappear { self.resetTimer() }
        }
      }
      Spacer()

      /* Speed control */
      VStack {
        HStack {
          Text("Slow").font(.system(size: 12))
          Slider(value: self.$speed, in: self.minSpeed ... self.maxSpeed)
            .disabled(!self.wordFinished)
          Text("Fast").font(.system(size: 12))
        }
        HStack {
          Text("Speed: \(String(Int(self.speed.rounded())))")
          Spacer()
          Text("Score: \(String(self.score))")
        }

        HStack {
          Button(action: self.handleResetSpeed) {
            Text("Reset speed").font(.system(size: 14))
          }.disabled(!self.wordFinished)
        }
      }.padding(.top, 30)

      /* Answer input */
      HStack {
        FocusableTextField(text: $answer, isFirstResponder: true)
          .frame(width: 300, height: 30)
          .textFieldStyle(RoundedBorderTextFieldStyle())
      }

      /* Word controls */

      HStack {
        if self.wordFinished {
          // TODO: change this to "Reveal"
          Button(action: self.handleNextWord) {
            Text("Skip")
          }
          Spacer()
          Button(action: self.handleReplay) {
            Image(systemName: "play.fill").modifier(IconButton())
          }.offset(x: 10)
          Spacer()
          Button(action: self.handleCheck) {
            Image(systemName: "checkmark").modifier(IconButton())
          }.disabled(self.answerTrimmed.isEmpty)
            .alert(isPresented: $alertIsVisible) { () -> Alert in
              Alert(
                title: self.isAnswerValid ? Text("✅ Correct!") : Text("🚩 Incorrect"),
                message: self.isAnswerValid ? Text("\"\(self.answerTrimmed)\" is correct") : Text("Try again"),
                dismissButton: self.isAnswerValid ? .default(Text("Next word"), action: self.handleNextWord) : .default(Text("OK"))
              )
            }

        } else {
          // Placeholder to maintain spacing while buttons are hidden
          Button(action: self.handleStop) { Image(systemName: "stop.fill").modifier(IconButton()).foregroundColor(.red) }
        }
      }
    }
    // Move the current UI up when the keyboard is active
    .padding(.bottom, keyboard.currentHeight)
    .padding(.horizontal, 40)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
