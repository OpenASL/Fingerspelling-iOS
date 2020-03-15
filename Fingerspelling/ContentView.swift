import Combine
import SwiftUI

// MARK: Views

struct ContentView: View {
  @State private var receptiveScore = 0
  @State private var expressiveScore = 0
  /// Timer used to delay playing the next word
  @State private var delayTimer: Timer? = nil
  @State private var isShowingSettings: Bool = false

  @EnvironmentObject private var playback: PlaybackService
  @EnvironmentObject private var feedback: FeedbackService
  @EnvironmentObject private var settings: UserSettings

  @ObservedObject private var keyboard = KeyboardResponder()

  private static let postSubmitDelay = 2.0 // seconds
  private static let nextWordDelay = 1.0 // seconds

  private var answerIsCorrect: Bool {
    self.feedback.answerTrimmed.lowercased() == self.playback.currentWord.lowercased()
  }

  var body: some View {
    VStack {
      GameStatusBar(
        receptiveScore: self.receptiveScore,
        expressiveScore: self.expressiveScore,
        speed: self.settings.speed,
        isShowingSettings: self.$isShowingSettings
      ).modifier(SystemServices())
      Divider().padding(.bottom, 10)

      if self.settings.gameMode == GameMode.receptive.rawValue {
        ReceptiveGameDisplay(
          onPlay: self.handlePlay,
          onStop: self.handleStop,
          onSubmit: self.handleSubmit,
          onReveal: self.handleReveal,
          showInput: !self.isShowingSettings
        )
      } else if self.settings.gameMode == GameMode.expressive.rawValue {
        ExpressiveGameDisplay(
          onReveal: self.handleRevealSpelling,
          onHide: self.handleHideSpelling,
          onContinue: self.handleNextSpellingWord
        )
      }
    }

    // Move the current UI up when the keyboard is active
    .padding(.bottom, keyboard.currentHeight)
    .padding(.top, 10)
    .padding(.horizontal, 20)
  }

  private func playWord() {
    self.playback.play()
    self.feedback.hide()
  }

  // MARK: Handlers

  private func handlePlay() {
    self.playWord()
  }

  private func handleNextWord() {
    self.playback.setNextWordPending()
    self.feedback.reset()

    self.delayTimer = delayFor(Self.nextWordDelay) {
      self.playWord()
    }
  }

  private func handleStop() {
    self.delayTimer?.invalidate()
    self.playback.stop()
    self.feedback.hide()
  }

  private func handleReveal() {
    self.playback.stop()
    self.feedback.reveal()
    delayFor(Self.postSubmitDelay) {
      self.feedback.hide()
      self.handleNextWord()
    }
  }

  private func handleSubmit() {
    // Prevent multiple submissions when pressing "return" key
    if self.feedback.hasCorrectAnswer {
      return
    }
    self.handleStop()
    self.feedback.show()
    if self.answerIsCorrect {
      self.feedback.markCorrect()
      self.receptiveScore += 1
      delayFor(Self.postSubmitDelay) {
        self.handleNextWord()
      }
    } else {
      delayFor(0.5) {
        self.feedback.hide()
      }
    }
  }

  private func handleRevealSpelling() {
    self.feedback.reveal()
  }

  private func handleHideSpelling() {
    self.feedback.hide()
  }

  private func handleNextSpellingWord() {
    self.playback.setNextWord()
    self.feedback.reset()
    self.expressiveScore += 1
  }
}

struct GameStatusBar: View {
  var receptiveScore: Int
  var expressiveScore: Int
  var speed: Double
  @Binding var isShowingSettings: Bool

  @EnvironmentObject var playback: PlaybackService
  @EnvironmentObject var settings: UserSettings

  static let fontSize: CGFloat = 14

  struct Indicator: View {
    var iconName: String
    var textContent: String

    var body: some View {
      HStack {
        Image(systemName: self.iconName).foregroundColor(.primary)
        Text(self.textContent).font(.system(size: GameStatusBar.fontSize)).bold()
      }
      .foregroundColor(Color.primary)
    }
  }

  var body: some View {
    HStack {
      Button(action: self.handleShowSettings) {
        Text("Fingerspelling - \(self.settings.gameMode)").font(.system(size: Self.fontSize))
      }
      Spacer()

      if self.settings.gameMode == GameMode.receptive.rawValue {
        Indicator(iconName: "checkmark", textContent: String(self.receptiveScore)).padding(.trailing, 10)
        Indicator(iconName: "metronome", textContent: String(Int(self.speed)))
      } else {
        Indicator(iconName: "hand.raised", textContent: String(self.expressiveScore))
      }
    }
    .sheet(isPresented: self.$isShowingSettings) {
      GameSettings(isPresented: self.$isShowingSettings)
        .modifier(SystemServices())
    }
  }

  func handleShowSettings() {
    self.playback.stop()
    self.isShowingSettings.toggle()
  }
}

struct ReceptiveGameDisplay: View {
  var onPlay: () -> Void
  var onStop: () -> Void
  var onSubmit: () -> Void
  var onReveal: () -> Void
  var showInput: Bool

  @EnvironmentObject private var playback: PlaybackService
  @EnvironmentObject private var feedback: FeedbackService
  @EnvironmentObject private var settings: UserSettings

  private static let minSpeed = 1.0
  private static let maxSpeed = 11.0

  var body: some View {
    Group {
      if self.feedback.hasCorrectAnswer || self.feedback.isRevealed {
        CurrentWordDisplay()
      }

      HStack {
        if self.showInput {
          AnswerInput(value: self.$feedback.answer, onSubmit: self.onSubmit).modifier(SystemServices())
        }
        if !self.feedback.shouldDisableControls {
          Spacer()
          Button(action: self.onReveal) {
            Text("Reveal").font(.system(size: 14))
          }.disabled(self.playback.isPlaying)
        }
      }
      Spacer()

      MainDisplay().frame(width: 100, height: 150)

      Spacer()
      SpeedControl(
        value: self.$settings.speed,
        minSpeed: Self.minSpeed,
        maxSpeed: Self.maxSpeed,
        disabled: self.playback.isPlaying
      )
      .padding(.bottom, 10)
      PlaybackControl(onPlay: self.onPlay, onStop: self.onStop).padding(.bottom, 10)
    }
  }
}

struct PlaybackControl: View {
  var onPlay: () -> Void
  var onStop: () -> Void

  @EnvironmentObject var playback: PlaybackService
  @EnvironmentObject var feedback: FeedbackService

  var body: some View {
    Group {
      if !self.playback.isActive {
        Button(action: self.onPlay) {
          Image(systemName: "play.fill")
            .font(.system(size: 18))
            .modifier(FullWidthButtonContent(disabled: self.feedback.shouldDisableControls))
        }.disabled(self.feedback.shouldDisableControls)
      } else {
        Button(action: self.onStop) {
          Image(systemName: "stop.fill")
            .font(.system(size: 18))
            .modifier(FullWidthGhostButtonContent())
        }
      }
    }
  }
}

struct ExpressiveGameDisplay: View {
  var onReveal: () -> Void
  var onHide: () -> Void
  var onContinue: () -> Void

  @EnvironmentObject private var feedback: FeedbackService

  var body: some View {
    Group {
      CurrentWordDisplay()
      Spacer()
      if self.feedback.isRevealed {
        SpellingDisplay()
      } else if !self.feedback.hasRevealed {
        Text("Fingerspell the word above.")
      }
      Spacer()
      ExpressiveControl(
        isRevealed: self.feedback.isRevealed,
        hasRevealed: self.feedback.hasRevealed,
        onReveal: self.onReveal,
        onHide: self.onHide,
        onContinue: self.onContinue
      ).padding(.bottom)
    }
  }
}

struct ExpressiveControl: View {
  var isRevealed: Bool
  var hasRevealed: Bool
  var onReveal: () -> Void
  var onHide: () -> Void
  var onContinue: () -> Void

  var body: some View {
    VStack {
      if self.hasRevealed {
        Button(action: self.onContinue) {
          Text("Next word").modifier(FullWidthButtonContent()).padding(.bottom)
        }
      }
      if self.isRevealed {
        Button(action: self.onHide) {
          Text("Hide").modifier(FullWidthGhostButtonContent())
        }
      } else {
        Button(action: self.onReveal) {
          Text("Reveal").modifier(FullWidthGhostButtonContent())
        }
      }
    }
  }
}

struct GameSettings: View {
  @Binding var isPresented: Bool

  @EnvironmentObject private var settings: UserSettings

  static let wordLengths = Array(3 ... 6) + [Int.max]

  struct LabeledPicker<SelectionValue: Hashable, Content: View>: View {
    var selection: Binding<SelectionValue>
    var label: String
    var content: () -> Content

    var body: some View {
      Section(header: Text(self.label.uppercased())) {
        Picker(selection: self.selection, label: Text(self.label)) {
          self.content()
        }.pickerStyle(SegmentedPickerStyle())
      }
    }
  }

  var body: some View {
    NavigationView {
      Form {
        LabeledPicker(selection: self.$settings.gameMode, label: "Mode") {
          ForEach(GameMode.allCases, id: \.self) {
            Text($0.rawValue).tag($0.rawValue)
          }
        }

        LabeledPicker(selection: self.$settings.maxWordLength, label: "Max word length") {
          ForEach(Self.wordLengths, id: \.self) {
            Text($0 == Int.max ? "Any" : "\($0) letters").tag($0)
          }
        }
      }
      .navigationBarTitle(Text("Fingerspelling"), displayMode: .inline)
    }
  }
}

struct CurrentWordDisplay: View {
  @EnvironmentObject var playback: PlaybackService

  var body: some View {
    Text(self.playback.currentWord.uppercased())
      .font(.system(.title, design: .monospaced))
      .minimumScaleFactor(0.8)
      .scaledToFill()
  }
}

struct AnswerInput: View {
  @Binding var value: String
  var onSubmit: () -> Void

  @EnvironmentObject var feedback: FeedbackService

  var body: some View {
    HStack {
      FocusableTextField(
        text: self.$value,
        isFirstResponder: true,
        placeholder: "WORD",
        textFieldShouldReturn: { _ in
          self.onSubmit()
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
      .frame(width: self.feedback.shouldDisableControls ? 0 : 280, height: self.feedback.hasCorrectAnswer ? 0 : 30)
      .opacity(self.feedback.shouldDisableControls ? 0 : 1)
    }
  }
}

struct MainDisplay: View {
  @EnvironmentObject var playback: PlaybackService
  @EnvironmentObject var feedback: FeedbackService

  var body: some View {
    VStack {
      if !self.playback.isPlaying {
        if !self.playback.hasPlayed {
          HStack {
            Text("Press ")
            Image(systemName: "play").foregroundColor(Color.blue)
            Text(" to begin.")
          }.frame(width: 200)
        }
        if self.feedback.isShown || self.feedback.hasCorrectAnswer {
          FeedbackDisplay(isCorrect: self.feedback.hasCorrectAnswer)
        }
      } else {
        // Need to pass SystemServices due to a bug in SwiftUI
        //   re: environment not getting passed to children
        WordPlayer().modifier(SystemServices())
      }
    }
  }
}

struct WordPlayer: View {
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
  var isCorrect: Bool

  var body: some View {
    Group {
      if self.isCorrect {
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

struct SpellingDisplay: View {
  @EnvironmentObject var playback: PlaybackService

  static let scaledSize: CGFloat = 165
  static let width: CGFloat = 100

  var body: some View {
    ScrollView(.horizontal) {
      HStack(alignment: .top, spacing: 0) {
        ForEach(self.playback.imageNames, id: \.self) { (_ imageName) in
          Image(imageName)
            .resizable()
            .frame(width: Self.scaledSize, height: Self.scaledSize)
            // Crop horizontal space around images
            .clipped()
            .frame(width: Self.width)
        }
      }
    }
    .frame(height: 185)
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

// MARK: State/service objects

// https://medium.com/better-programming/swiftui-microservices-c7002228710

final class PlaybackService: ObservableObject {
  @Published var currentWord = ""
  @Published var letterIndex = 0
  @Published var isPlaying = false
  @Published var playTimer: LoadingTimer?
  @Published var isPendingNextWord: Bool = false
  @Published var hasPlayed = false

  private var settings = SystemServices.settings
  private static let numerator = 2.0 // Higher value = slower speeds

  init() {
    self.currentWord = getRandomWord()
    self.playTimer = self.getTimer()
  }

  var currentLetterImage: UIImage {
    self.uiImages[self.letterIndex]
  }

  var currentLetterIsRepeat: Bool {
    self.letterIndex > 0 &&
      Array(self.currentWord)[self.letterIndex - 1] == Array(self.currentWord)[self.letterIndex]
  }

  var isActive: Bool {
    self.isPlaying || self.isPendingNextWord
  }

  var imageNames: [String] {
    Array(self.currentWord).map { "\(String($0).uppercased())-lauren-nobg" }
  }

  private var uiImages: [UIImage] {
    self.imageNames.map { UIImage(named: $0)! }
  }

  func reset() {
    self.stop()
    self.setNextWord()
    self.hasPlayed = false
  }

  func play() {
    self.letterIndex = 0
    self.isPlaying = true
    self.isPendingNextWord = false
    self.hasPlayed = true
  }

  func stop() {
    self.resetTimer()
    self.letterIndex = 0
    self.isPlaying = false
    self.isPendingNextWord = false
  }

  func setNextLetter() {
    if self.letterIndex >= (self.uiImages.count - 1) {
      self.isPlaying = false
    } else {
      self.letterIndex += 1
    }
  }

  func setNextWordPending() {
    self.setNextWord()
    self.isPendingNextWord = true
  }

  func setNextWord() {
    self.currentWord = getRandomWord()
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

final class FeedbackService: ObservableObject {
  @Published var answer: String = ""
  @Published var isShown: Bool = false
  @Published var hasCorrectAnswer: Bool = false
  @Published var hasRevealed: Bool = false
  @Published var isRevealed: Bool = false

  var shouldDisableControls: Bool {
    self.hasCorrectAnswer || self.isRevealed
  }

  var answerTrimmed: String {
    self.answer.trimmingCharacters(in: .whitespaces)
  }

  func reset() {
    self.answer = ""
    self.hasCorrectAnswer = false
    self.isShown = false
    self.hasRevealed = false
    self.isRevealed = false
  }

  func show() {
    self.isShown = true
  }

  func hide() {
    self.isShown = false
    self.isRevealed = false
  }

  func reveal() {
    self.hasRevealed = true
    self.isRevealed = true
    self.isShown = false
  }

  func markCorrect() {
    self.hasCorrectAnswer = true
  }
}

// MARK: User settings

enum GameMode: String, CaseIterable {
  case receptive = "Receptive"
  case expressive = "Expressive"
}

/// Simple wrapper around UserDefaults to make settings observables
final class UserSettings: ObservableObject {
  let objectWillChange = PassthroughSubject<Void, Never>()

  private var playback: PlaybackService {
    SystemServices.playback
  }

  private var feedback: FeedbackService {
    SystemServices.feedback
  }

  init() {
    Words = AllWords.filter { $0.count <= self.maxWordLength }
  }

  // Settings go here

  @UserDefault("speed", defaultValue: 3.0)
  var speed: Double {
    willSet {
      self.objectWillChange.send()
    }
  }

  // Note: we use the raw values of the enum so that it can be properly
  //   serialized to UserDefaults
  @UserDefault("gameMode", defaultValue: GameMode.receptive.rawValue)
  var gameMode: String {
    willSet {
      self.playback.reset()
      self.feedback.reset()

      self.objectWillChange.send()
    }
  }

  @UserDefault("maxWordLength", defaultValue: Int.max)
  var maxWordLength: Int {
    willSet {
      Words = AllWords.filter { $0.count <= newValue }
      self.playback.setNextWord()

      self.objectWillChange.send()
    }
  }
}

// MARK: ViewModifiers

// https://medium.com/swlh/swiftui-and-the-missing-environment-object-1a4bf8913ba7
struct SystemServices: ViewModifier {
  static var playback = PlaybackService()
  static var feedback = FeedbackService()
  static var settings = UserSettings()

  func body(content: Content) -> some View {
    content
      .environmentObject(Self.settings)
      .environmentObject(Self.playback)
      .environmentObject(Self.feedback)
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

// MARK: Utilities

private func getRandomWord() -> String {
  let word = Words.randomElement()!
  print("current word: " + word)
  return word
}

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

// MARK: Preview

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    let playback = SystemServices.playback
    let feedback = SystemServices.feedback

    // Modify these during development to update the preview
    playback.isPlaying = false
    playback.currentWord = "foo"
    feedback.isShown = false

    return ContentView().modifier(SystemServices())
  }
}
