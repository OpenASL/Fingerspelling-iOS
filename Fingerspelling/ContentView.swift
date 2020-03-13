import Combine
import SwiftUI

// MARK: Utilities

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

private func getNextWord() -> String {
  let word = Words.randomElement()!
  print("current word: " + word)
  return word
}

@discardableResult
func delayFor(_ seconds: Double, onComplete: @escaping () -> Void) -> Timer {
  Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
    onComplete()
  }
}

// MARK: ViewModifiers

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

// MARK: State/service objects

final class PlaybackService: ObservableObject {
  @Published var currentWord = ""
  @Published var letterIndex = 0
  @Published var isPlaying = false
  @Published var playTimer: LoadingTimer?
  @ObservedObject var settings = UserSettings()

  private static let numerator = 2.0 // Higher value = slower speeds

  init() {
    self.currentWord = getNextWord()
    self.playTimer = self.getTimer()
  }

  var currentLetterImage: UIImage {
    self.images[self.letterIndex]
  }

  var currentLetterIsRepeat: Bool {
    self.letterIndex > 0 &&
      Array(self.currentWord)[self.letterIndex - 1] == Array(self.currentWord)[self.letterIndex]
  }

  private var images: [UIImage] {
    let letters = Array(self.currentWord).map { "\(String($0).uppercased())-lauren-nobg" }
    return letters.map { UIImage(named: $0)! }
  }

  func play() {
    self.letterIndex = 0
    self.isPlaying = true
  }

  func stop() {
    self.resetTimer()
    self.play()
    self.isPlaying = false
  }

  func setNextLetter() {
    if self.letterIndex >= (self.images.count - 1) {
      self.isPlaying = false
    } else {
      self.letterIndex += 1
    }
  }

  func setNextWord() {
    self.currentWord = getNextWord()
  }

  func startTimer() {
    self.playTimer!.start()
  }

  func resetTimer() {
    self.playTimer!.cancel()
    self.playTimer = self.getTimer()
  }

  private func getTimer() -> LoadingTimer {
    let every = Self.numerator / self.settings.speed
    return LoadingTimer(every: every)
  }
}

// https://medium.com/swlh/swiftui-and-the-missing-environment-object-1a4bf8913ba7
struct SystemServices: ViewModifier {
  static var playback = PlaybackService()

  func body(content: Content) -> some View {
    content
      .environmentObject(Self.playback)
  }
}

// MARK: Views

struct GameStatusBar: View {
  var score: Int
  var speed: Double

  var scoreDisplay: some View {
    HStack {
      Image(systemName: "checkmark").foregroundColor(.primary)
      Text(String(self.score)).font(.system(size: 14)).bold()
    }
    .foregroundColor(Color.primary)
  }

  var speedDisplay: some View {
    HStack {
      Image(systemName: "metronome").foregroundColor(.primary)
      Text(String(Int(self.speed))).font(.system(size: 14))
    }.padding(.horizontal, 10)
      .foregroundColor(Color.primary)
  }

  var body: some View {
    HStack {
      self.scoreDisplay
      Spacer()
      self.speedDisplay
    }
  }
}

struct LetterDisplay: View {
  @EnvironmentObject var playback: PlaybackService

  var body: some View {
    // XXX: Complicated implementation of an animated image
    //   since there doesn't seem to be a better way to do this in
    //   SwiftUI yet: https://stackoverflow.com/a/57749621/1157536
    Image(uiImage: self.playback.currentLetterImage)
      .resizable()
      .frame(width: 225, height: 225)
      .scaledToFit()
      .offset(x: self.playback.currentLetterIsRepeat ? -20 : 0)
      .onReceive(
        self.playback.playTimer!.publisher,
        perform: { _ in
          self.playback.setNextLetter()
        }
      )
      .onAppear {
        self.playback.resetTimer()
        self.playback.startTimer()
      }
      .onDisappear {
        self.playback.resetTimer()
      }
  }
}

struct FeedbackDisplay: View {
  var correct: Bool

  var body: some View {
    Group {
      if self.correct {
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
}

struct SpeedControl: View {
  @Binding var value: Double

  var minSpeed: Double
  var maxSpeed: Double
  var disabled: Bool

  var body: some View {
    HStack {
      Image(systemName: "tortoise").foregroundColor(.gray)
      Slider(value: self.$value, in: self.minSpeed ... self.maxSpeed, step: 1)
        .disabled(self.disabled)
      Image(systemName: "hare").foregroundColor(.gray)
    }
  }
}

struct ContentView: View {
  @State private var answer: String = ""
  @State private var delayTimer: Timer? = nil
  @State private var score = 0
  @State private var isShowingFeedback: Bool = false
  @State private var isPendingNextWord: Bool = false
  @State private var hasCorrectAnswer: Bool = false
  @State private var isRevealed: Bool = false

  @ObservedObject private var settings = UserSettings()
  @ObservedObject private var keyboard = KeyboardResponder()

  @EnvironmentObject private var playback: PlaybackService

  private static let minSpeed = 1.0
  private static let maxSpeed = 11.0
  private static let postSubmitDelay = 2.0 // seconds
  private static let nextWordDelay = 1.0 // seconds

  // MARK: Computed properties

  private var currentWord: String {
    self.playback.currentWord
  }

  private var answerTrimmed: String {
    self.answer.trimmingCharacters(in: .whitespaces)
  }

  private var isAnswerValid: Bool {
    self.answerTrimmed.lowercased() == self.currentWord.lowercased()
  }

  private var isPlaying: Bool {
    self.playback.isPlaying || self.isPendingNextWord
  }

  private var shouldDisableControls: Bool {
    self.hasCorrectAnswer || self.isRevealed
  }

  // MARK: Nested views

  private var correctWordDisplay: some View {
    Text(self.currentWord.uppercased())
      .font(.system(.title, design: .monospaced))
      .minimumScaleFactor(0.8)
      .scaledToFill()
  }

  private var controls: some View {
    HStack {
      if !self.isPlaying {
        Button(action: self.handlePlay) {
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

  private var answerInput: some View {
    HStack {
      FocusableTextField(
        text: self.$answer,
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

  private var mainDisplay: some View {
    VStack {
      if !self.playback.isPlaying {
        if self.isShowingFeedback || self.hasCorrectAnswer {
          FeedbackDisplay(correct: self.hasCorrectAnswer)
        }
      } else {
        // Need to pass SystemServices due to a bug in SwiftUI
        //   re: environment not getting passed to children
        LetterDisplay().modifier(SystemServices())
      }
    }.frame(width: 100, height: 150)
  }

  var body: some View {
    VStack {
      GameStatusBar(score: self.score, speed: self.settings.speed)
      Divider().padding(.bottom, 10)

      if self.hasCorrectAnswer || self.isRevealed {
        self.correctWordDisplay
      }

      HStack {
        self.answerInput
        if !self.shouldDisableControls {
          Spacer()
          Button(action: self.handleReveal) {
            Text("Reveal").font(.system(size: 14))
          }
        }
      }
      Spacer()
      self.mainDisplay
      Spacer()
      SpeedControl(
        value: self.$settings.speed,
        minSpeed: Self.minSpeed,
        maxSpeed: Self.maxSpeed,
        disabled: self.playback.isPlaying
      )
      .padding(.bottom, 10)
      self.controls.padding(.bottom, 10)
    }
    // Move the current UI up when the keyboard is active
    .padding(.bottom, keyboard.currentHeight)
    .padding(.top, 10)
    .padding(.horizontal, 20)
  }

  private func playWord() {
    self.playback.play()
    self.isShowingFeedback = false
  }

  // MARK: Handlers

  private func handlePlay() {
    self.playWord()
  }

  private func handleNextWord() {
    self.answer = ""
    self.playback.setNextWord()
    self.hasCorrectAnswer = false
    self.isPendingNextWord = true
    self.isShowingFeedback = false
    self.delayTimer = delayFor(Self.nextWordDelay) {
      self.playWord()
      self.isPendingNextWord = false
    }
  }

  private func handleStop() {
    self.delayTimer?.invalidate()
    self.playback.stop()
    self.isShowingFeedback = false
    self.isPendingNextWord = false
  }

  private func handleReveal() {
    self.isRevealed = true
    self.isShowingFeedback = false
    self.playback.isPlaying = false
    delayFor(Self.postSubmitDelay) {
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
      delayFor(Self.postSubmitDelay) {
        self.handleNextWord()
      }
    } else {
      delayFor(Self.postSubmitDelay) {
        self.isShowingFeedback = false
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    let playback = PlaybackService()
    playback.isPlaying = true
    return ContentView().environmentObject(playback)
  }
}
