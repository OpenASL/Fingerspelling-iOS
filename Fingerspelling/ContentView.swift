import Combine
import SwiftUI

// MARK: Views

struct ContentView: View {
  @ObservedObject private var keyboard = KeyboardResponder()

  @EnvironmentObject private var settings: UserSettings
  @EnvironmentObject private var game: GameState

  struct GameDisplay: ViewModifier {
    func body(content: Content) -> some View {
      content
        .padding()
        .font(.system(size: 24))
    }
  }

  var body: some View {
    ZStack {
      if self.game.isShowingSettings {
        GameSettings().modifier(SystemServices())
      } else {
        Group {
          if self.game.mode == GameMode.receptive {
            ReceptiveGame().modifier(SystemServices())
          } else if self.game.mode == GameMode.expressive {
            ExpressiveGame().modifier(SystemServices())
          }
        }
        .padding(.top, 10)
        .padding(.horizontal, 20)
        // Move the current UI up when the keyboard is active
        .padding(.bottom, self.keyboard.currentHeight)
      }
      SideMenu(width: 250,
               isOpen: self.game.isMenuOpen,
               onClose: { self.game.isMenuOpen.toggle() })
    }
  }
}

// MARK: Receptive game views

struct ReceptiveGame: View {
  /// Timer used to delay playing the next word
  @State private var delayTimer: Timer? = nil

  @EnvironmentObject private var game: GameState
  @EnvironmentObject private var playback: PlaybackService
  @EnvironmentObject private var feedback: FeedbackService
  @EnvironmentObject private var settings: UserSettings

  private static let postSubmitDelay = 2.0 // seconds
  private static let nextWordDelay = 1.0 // seconds
  private static let minSpeed = 1.0
  private static let maxSpeed = 11.0

  private var answerIsCorrect: Bool {
    self.feedback.answerTrimmed.lowercased() == self.playback.currentWord.lowercased()
  }

  var body: some View {
    VStack {
      GameStatusBar {
        HStack {
          Indicator(iconName: "checkmark", textContent: String(self.game.receptiveScore)).padding(.trailing, 10)
          Indicator(iconName: "metronome", textContent: String(Int(self.settings.speed)))
        }
      }.modifier(SystemServices())
      Divider().padding(.bottom, 10)

      if self.feedback.hasCorrectAnswer || self.feedback.isRevealed {
        CurrentWordDisplay()
      }

      HStack {
        if !self.game.isMenuOpen {
          AnswerInput(value: self.$feedback.answer, onSubmit: self.handleSubmit, isCorrect: self.answerIsCorrect).modifier(SystemServices())
        }
        if !self.feedback.shouldDisableControls {
          Spacer()
          Button(action: self.handleReveal) {
            Text("Reveal").font(.system(size: 14)).foregroundColor(.primary)
          }.disabled(self.playback.isPlaying)
        }
      }
      Spacer()

      MainDisplay(onPlay: self.handlePlay).frame(width: 100, height: 150)

      Spacer()
      SpeedControl(
        value: self.$settings.speed,
        minSpeed: Self.minSpeed,
        maxSpeed: Self.maxSpeed,
        disabled: self.playback.isPlaying
      )
      .padding(.bottom, 10)
      PlaybackControl(onPlay: self.handlePlay, onStop: self.handleStop).padding(.bottom, 10)
    }
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
    self.feedback.show()
    if self.answerIsCorrect {
      self.handleStop()
      self.feedback.markCorrect()
      self.game.receptiveScore += 1
      delayFor(Self.postSubmitDelay) {
        self.handleNextWord()
      }
    } else {
      self.feedback.markIncorrect()
      delayFor(0.5) {
        self.feedback.hide()
      }
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
      if !self.playback.isActive && !self.feedback.shouldDisableControls {
        Button(action: self.onPlay) {
          Image(systemName: "play.fill")
            .font(.system(size: 18))
            .modifier(FullWidthButtonContent())
        }
      } else {
        Button(action: self.onStop) {
          Image(systemName: "stop.fill")
            .font(.system(size: 18))
            .modifier(FullWidthGhostButtonContent())
        }.disabled(self.feedback.shouldDisableControls)
      }
    }
  }
}

struct MainDisplay: View {
  var onPlay: () -> Void

  @EnvironmentObject var playback: PlaybackService
  @EnvironmentObject var feedback: FeedbackService

  var body: some View {
    VStack {
      if !self.playback.isPlaying {
        if !self.feedback.hasSubmitted {
          if !self.playback.hasPlayed {
            Button(action: self.onPlay) {
              HStack {
                Text("Press ").foregroundColor(Color.primary)
                Image(systemName: "play").foregroundColor(Color.accentColor)
                Text(" to begin.").foregroundColor(Color.primary)
              }.frame(width: 200, height: 150)
            }
          } else {
            Text("Enter the word you saw.").frame(width: 200, height: 150)
          }
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
        CheckmarkAnimation(startX: -120, startY: -370)
      }
    }
  }
}

struct CheckmarkAnimation: View {
  @State private var displayBorder = false
  @State private var displayCheckmark = false

  var startX: CGFloat
  var startY: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .strokeBorder(style: StrokeStyle(lineWidth: displayBorder ? 5 : 64))
        .frame(width: 128, height: 128)
        .foregroundColor(.green)
        .animation(Animation.easeOut(duration: 0.6).speed(3.0))
        .onAppear {
          self.displayBorder.toggle()
        }
      Path { path in
        path.move(to: CGPoint(x: self.startX, y: self.startY))
        path.addLine(to: CGPoint(x: self.startX, y: self.startY))
        path.addLine(to: CGPoint(x: self.startX + 20, y: self.startY + 20))
        path.addLine(to: CGPoint(x: self.startX + 60, y: self.startY - 20))
      }.trim(from: 0, to: displayCheckmark ? 1 : 0)
        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        .foregroundColor(displayCheckmark ? .green : .white)
        .offset(x: 155, y: 450)
        .animation(Animation.interpolatingSpring(stiffness: 160, damping: 20).delay(0.3))
        .onAppear {
          self.displayCheckmark.toggle()
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

struct AnswerInput: View {
  @Binding var value: String
  var onSubmit: () -> Void
  var isCorrect: Bool = true
  var disabled: Bool = false

  @EnvironmentObject var feedback: FeedbackService

  var body: some View {
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
      },
      onUpdate: { textField in
        if self.feedback.isShown, !self.isCorrect {
          textField.layer.cornerRadius = 4.0
          textField.layer.borderColor = UIColor.red.cgColor
          textField.layer.borderWidth = 2.0
        } else {
          textField.layer.cornerRadius = 8.0
          textField.layer.borderColor = nil
          textField.layer.borderWidth = 0
        }
      }
    )
    // Hide input after success.
    // Note: we use opacity to hide because the text field needs to be present for the keyboard
    //   to remain on the screen and we set the frame to 0 to make room for the correct word display.
    .frame(width: self.feedback.shouldDisableControls ? 0 : 280, height: self.feedback.hasCorrectAnswer ? 0 : 30)
    .opacity(self.feedback.shouldDisableControls ? 0 : 1)
  }
}

// MARK: Expressive game views

struct ExpressiveGame: View {
  @EnvironmentObject private var game: GameState
  @EnvironmentObject private var playback: PlaybackService
  @EnvironmentObject private var feedback: FeedbackService

  var body: some View {
    VStack {
      GameStatusBar {
        HStack {
          Indicator(iconName: "checkmark", textContent: String(self.game.expressiveScore))
        }
      }.modifier(SystemServices())
      Divider().padding(.bottom, 10)
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
        onReveal: self.handleRevealSpelling,
        onHide: self.handleHideSpelling,
        onContinue: self.handleContinue
      ).padding(.bottom)
    }
  }

  private func playWord() {
    self.playback.play()
    self.feedback.hide()
  }

  // MARK: Handlers

  private func handleRevealSpelling() {
    self.feedback.reveal()
  }

  private func handleHideSpelling() {
    self.feedback.hide()
  }

  private func handleContinue() {
    self.playback.setNextWord()
    self.feedback.reset()
    self.game.expressiveScore += 1
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

// MARK: Common views

struct Indicator: View {
  var iconName: String
  var textContent: String
  var fontSize: CGFloat = 14

  var body: some View {
    HStack {
      Image(systemName: self.iconName).foregroundColor(.primary)
      Text(self.textContent).font(.system(size: self.fontSize, design: .monospaced))
    }
    .foregroundColor(Color.primary)
  }
}

struct GameStatusBar<Content: View>: View {
  var fontSize: CGFloat = 14
  var content: () -> Content

  @EnvironmentObject private var game: GameState
  @EnvironmentObject private var playback: PlaybackService
  @EnvironmentObject private var settings: UserSettings

  var body: some View {
    HStack {
      Button(action: self.handleOpenMenu) {
        Image(systemName: "line.horizontal.3")
        Image(systemName: self.game.mode == GameMode.receptive ? "eyeglasses" : "hand.raised")
      }
      Spacer()

      self.content()
    }
    .foregroundColor(.primary)
  }

  func handleOpenMenu() {
    self.game.isMenuOpen.toggle()
    self.playback.stop()
  }
}

struct GameSettings: View {
  @EnvironmentObject private var game: GameState
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
        LabeledPicker(selection: self.$settings.maxWordLength, label: "Max word length") {
          ForEach(Self.wordLengths, id: \.self) {
            Text($0 == Int.max ? "Any" : "\($0) letters").tag($0)
          }
        }
      }
      .navigationBarTitle(Text("Settings"), displayMode: .inline)
      // TODO: Make this navigation animation better
      .navigationBarItems(trailing: Button(action: self.handleClose) {
        Image(systemName: "xmark").padding()
      })
    }
  }

  func handleClose() {
    withAnimation {
      self.game.isShowingSettings.toggle()
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

struct SideMenu: View {
  let width: CGFloat
  let isOpen: Bool
  let onClose: () -> Void

  @Environment(\.colorScheme) var colorScheme

  struct MenuContent: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var feedback: FeedbackService
    @EnvironmentObject var playback: PlaybackService

    var body: some View {
      VStack(alignment: .leading) {
        Text("ASL Fingerspelling")
          .font(.system(size: 18))
          .fontWeight(.light)
          .padding(.top, 50)

        Button(action: {
          self.changeGameMode(.receptive)
        }) {
          Image(systemName: "eyeglasses")
            .imageScale(.large)
          Text("Receptive")
            .fontWeight(self.game.mode == GameMode.receptive ? .bold : .regular)
        }
        .padding(.top, 50)

        Button(action: {
          self.changeGameMode(.expressive)
        }) {
          Image(systemName: "hand.raised")
            .imageScale(.large)
          Text("Expressive")
            .fontWeight(self.game.mode == GameMode.expressive ? .bold : .regular)
        }
        .padding(.top, 30)

        Button(action: {
          self.game.isShowingSettings.toggle()
          self.game.isMenuOpen.toggle()
        }) {
          Image(systemName: "gear")
            .imageScale(.large)
          Text("Settings")
        }
        .padding(.top, 30)
        Spacer()
      }
      .font(.system(size: 18))
      .foregroundColor(.primary)
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .edgesIgnoringSafeArea(.all)
    }

    func changeGameMode(_ gameMode: GameMode) {
      self.game.mode = gameMode
      self.game.isMenuOpen.toggle()
      self.playback.reset()
      self.feedback.reset()
      self.feedback.hasSubmitted = false
    }
  }

  var body: some View {
    ZStack {
      GeometryReader { _ in
        EmptyView()
      }
      .background(Color.gray.opacity(0.3))
      .opacity(self.isOpen ? 1.0 : 0.0)
      .animation(Animation.easeIn(duration: 0.2))
      .onTapGesture {
        self.onClose()
      }

      HStack {
        MenuContent()
          .frame(width: self.width)
          .background(self.colorScheme == .dark ? Color.black : Color.white)
          .offset(x: self.isOpen ? 0 : -self.width)
          .animation(.easeOut(duration: 0.2))
        Spacer()
      }
    }
  }
}

// MARK: State/service objects

// https://medium.com/better-programming/swiftui-microservices-c7002228710

final class GameState: ObservableObject {
  @Published var receptiveScore = 0
  @Published var expressiveScore = 0
  @Published var isShowingSettings = false
  @Published var isMenuOpen = false
  @Published var mode: GameMode = GameMode.receptive
}

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
  @Published var hasSubmitted: Bool = false
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
    self.hasSubmitted = true
  }

  func markIncorrect() {
    self.hasCorrectAnswer = false
    self.hasSubmitted = true
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
      self.feedback.hasSubmitted = false

      self.objectWillChange.send()
    }
  }

  @UserDefault("maxWordLength", defaultValue: Int.max)
  var maxWordLength: Int {
    willSet {
      Words = AllWords.filter { $0.count <= newValue }
      self.playback.setNextWord()

      self.feedback.reset()
      self.objectWillChange.send()
    }
  }
}

// MARK: ViewModifiers

// https://medium.com/swlh/swiftui-and-the-missing-environment-object-1a4bf8913ba7
struct SystemServices: ViewModifier {
  static var game = GameState()
  static var playback = PlaybackService()
  static var feedback = FeedbackService()
  static var settings = UserSettings()

  func body(content: Content) -> some View {
    content
      .environmentObject(Self.game)
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
  var background: Color = Color.accentColor
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
  var color: Color = Color.accentColor

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
