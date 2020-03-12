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

@discardableResult
func delayFor(_ seconds: Double, onComplete: @escaping () -> Void) -> Timer {
  Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
    onComplete()
  }
}

struct IconButton: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding()
      .font(.system(size: 24))
  }
}

struct MainDisplayIcon: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding()
      .font(.system(size: 120))
  }
}

struct FullWidthButtonContent: ViewModifier {
  var background: Color = Color.blue
  var foregroundColor: Color = Color.white
  var disabled: Bool = false

  func body(content: Content) -> some View {
    content
      .frame(minWidth: 0, maxWidth: .infinity)
      .padding()
      .background(self.background)
      .foregroundColor(self.foregroundColor)
      .cornerRadius(40)
      .opacity(self.disabled ? 0.5 : 1)
  }
}

struct FullWidthGhostButtonContent: ViewModifier {
  var color: Color = Color.blue

  func body(content: Content) -> some View {
    content
      .frame(minWidth: 0, maxWidth: .infinity)
      .padding()
      .overlay(
        RoundedRectangle(cornerRadius: 40)
          .stroke(self.color, lineWidth: 1)
      )
      .foregroundColor(self.color)
  }
}

private func getNextWord() -> String {
  Words.randomElement()!
}

struct ContentView: View {
  @State private var letterIndex = 0
  @State private var answer: String = ""
  @State private var playTimer: LoadingTimer? = nil
  @State private var delayTimer: Timer? = nil
  @State private var currentWord = ""
  @State private var score = 0
  @State private var isShowingFeedback: Bool = false
  @State private var isPendingNextWord: Bool = false
  @State private var hasCorrectAnswer: Bool = false
  @State private var isRevealed: Bool = false
  @State private var isStopped = true
  @ObservedObject var settings = UserSettings()
  @ObservedObject private var keyboard = KeyboardResponder()

  private let numerator = 2.0 // Higher value = slower speeds
  private let minSpeed = 1.0
  private let maxSpeed = 11.0
  private let postSubmitDelay = 2.0 // seconds
  private let nextWordDelay = 1.0 // seconds
  private var words = [String]()

  init() {
    // XXX Setting state variable in init: https://stackoverflow.com/a/60028709/1157536
    self._currentWord = State<String>(initialValue: getNextWord())
    self._playTimer = State<LoadingTimer?>(initialValue: self.getTimer())
  }

  private var answerTrimmed: String {
    self.answer.trimmingCharacters(in: .whitespaces)
  }

  private var isAnswerValid: Bool {
    self.answerTrimmed.lowercased() == self.currentWord.lowercased()
  }

  private var images: [UIImage] {
    let letters = Array(self.currentWord).map { "\(String($0).uppercased())-lauren-nobg" }
    return letters.map { UIImage(named: $0)! }
  }

  private var isPlaying: Bool {
    !self.isStopped || self.isPendingNextWord
  }

  private var shouldDisableControls: Bool {
    self.hasCorrectAnswer || self.isRevealed
  }

  var body: some View {
    VStack {
      HStack {
        self.createScoreDisplay()
        Spacer()
        self.createSpeedDisplay()
      }
      Divider().padding(.bottom, 10)

      if self.hasCorrectAnswer || self.isRevealed {
        self.createCorrectWordDisplay()
      }

      HStack {
        self.createAnswerInput()
        Spacer()
        if !self.shouldDisableControls {
          Button(action: self.handleReveal) {
            Text("Reveal").font(.system(size: 14))
          }
        }
      }
      Spacer()
      self.createMainDisplay()
      Spacer()
      self.createSpeedControl().padding(.bottom, 10)
      self.createControls().padding(.bottom, 10)
    }
    // Move the current UI up when the keyboard is active
    .padding(.bottom, keyboard.currentHeight)
    .padding(.top, 10)
    .padding(.horizontal, 20)
  }

  private func createSpeedDisplay() -> some View {
    HStack {
      Image(systemName: "metronome").foregroundColor(.primary)
      Text(String(Int(self.settings.speed))).font(.system(size: 14))
    }.padding(.horizontal, 10)
      .foregroundColor(Color.primary)
  }

  private func createScoreDisplay() -> some View {
    HStack {
      Image(systemName: "checkmark").foregroundColor(.primary)
      Text(String(self.score)).font(.system(size: 14)).bold()
    }
    .foregroundColor(Color.primary)
  }

  private func createMainDisplay() -> some View {
    VStack {
      if self.isStopped {
        if self.isShowingFeedback || self.hasCorrectAnswer {
          self.createFeedbackDisplay()
        }
      } else {
        self.createLetterDisplay()
      }
    }.frame(width: 100, height: 150)
  }

  private func createFeedbackDisplay() -> some View {
    Group {
      if self.hasCorrectAnswer {
        Image(systemName: "checkmark.circle")
          .modifier(MainDisplayIcon())
          .foregroundColor(Color.green)

      } else {
        Image(systemName: "xmark.circle")
          .modifier(MainDisplayIcon())
          .foregroundColor(Color.red)
      }
    }
  }

  private func createLetterDisplay() -> some View {
    Image(uiImage: self.images[self.letterIndex])
      .resizable()
      .frame(width: 225, height: 225)
      .scaledToFit()
      .offset(x: self.letterIndex > 0 && Array(self.currentWord)[self.letterIndex - 1] == Array(self.currentWord)[self.letterIndex] ? -20 : 0)
      .onReceive(
        self.playTimer!.publisher,
        perform: { _ in
          self.letterIndex += 1
          if self.letterIndex >= self.images.count {
            self.isStopped = true
          }
        }
      )
      .onAppear {
        self.resetTimer()
        self.playTimer!.start()
      }
      .onDisappear { self.resetTimer() }
  }

  private func createSpeedControl() -> some View {
    HStack {
      Image(systemName: "tortoise").foregroundColor(.gray)
      Slider(value: self.$settings.speed, in: self.minSpeed ... self.maxSpeed, step: 1)
        .disabled(!self.isStopped)
      Image(systemName: "hare").foregroundColor(.gray)
    }
  }

  private func createAnswerInput() -> some View {
    HStack {
      FocusableTextField(
        text: $answer,
        isFirstResponder: true,
        placeholder: "WORD",
        textFieldShouldReturn: { _ in
          self.handleSubmit()
          return true
        },
        modifyTextField: { textField in
          textField.borderStyle = .roundedRect
          textField.autocapitalizationType = .allCharacters
          textField.autocorrectionType = .no
          textField.returnKeyType = .done
          textField.keyboardType = .asciiCapable
          textField.font = .monospacedSystemFont(ofSize: 18.0, weight: .regular)
          textField.clearButtonMode = .whileEditing
          return textField
        }
      )
      // Hide input after success.
      // Note: we use opacity to hide because the text field needs to be present for the keyboard
      //   to remain on the screen and we set the frame to 0 to make room for the correct word display.
      .frame(width: self.shouldDisableControls ? 0 : 280, height: self.hasCorrectAnswer ? 0 : 30)
      .opacity(self.shouldDisableControls ? 0 : 1)
    }
  }

  private func createCorrectWordDisplay() -> some View {
    Text(self.currentWord.uppercased())
      .font(.system(.title, design: .monospaced))
      .minimumScaleFactor(0.8)
      .scaledToFill()
  }

  private func createControls() -> some View {
    HStack {
      if !self.isPlaying {
        Button(action: self.handleReplay) {
          Image(systemName: "play.fill")
            .font(.system(size: 18))
            .modifier(FullWidthButtonContent(disabled: self.shouldDisableControls))
        }.disabled(self.shouldDisableControls)
      } else {
        Button(action: self.handleStop) {
          Image(systemName: "stop.fill")
            .font(.system(size: 18))
            .modifier(FullWidthGhostButtonContent())
        }
      }
    }
  }

  private func createCheckButton() -> some View {
    Button(action: self.handleSubmit) {
      Image(systemName: "checkmark").modifier(IconButton())
    }.disabled(self.answerTrimmed.isEmpty || self.hasCorrectAnswer)
  }

  private func getTimer() -> LoadingTimer {
    let every = self.numerator / self.settings.speed
    return LoadingTimer(every: every)
  }

  private func resetTimer() {
    self.playTimer!.cancel()
    self.playTimer = self.getTimer()
  }

  private func resetWord() {
    self.letterIndex = 0
    self.isStopped = false
    self.isShowingFeedback = false
  }

  private func handleReplay() {
    self.resetWord()
  }

  private func handleNextWord() {
    self.answer = ""
    self.currentWord = getNextWord()
    self.hasCorrectAnswer = false
    self.isPendingNextWord = true
    self.isShowingFeedback = false
    self.delayTimer = delayFor(self.nextWordDelay) {
      self.resetWord()
      self.isPendingNextWord = false
    }
  }

  private func handleStop() {
    self.delayTimer?.invalidate()
    self.resetTimer()
    self.resetWord()
    self.isPendingNextWord = false
    self.isStopped = true
  }

  private func handleReveal() {
    self.isRevealed = true
    self.isShowingFeedback = false
    delayFor(self.postSubmitDelay) {
      self.isRevealed = false
      self.handleNextWord()
    }
  }

  private func handleSubmit() {
    // Prevent multiple submissions from pressing "return" key
    if self.hasCorrectAnswer {
      return
    }
    self.handleStop()
    self.isShowingFeedback = true
    if self.isAnswerValid {
      self.hasCorrectAnswer = true
      self.score += 1
      delayFor(self.postSubmitDelay) {
        self.handleNextWord()
      }
    } else {
      delayFor(self.postSubmitDelay) {
        self.isShowingFeedback = false
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
