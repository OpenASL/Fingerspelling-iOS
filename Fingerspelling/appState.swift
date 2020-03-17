import Combine
import SwiftUI

/// View modifier to set all of the main services on the environment
/// https://medium.com/swlh/swiftui-and-the-missing-environment-object-1a4bf8913ba7
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

enum GameMode: String, CaseIterable {
  case receptive = "Receptive"
  case expressive = "Expressive"
}

final class GameState: ObservableObject {
  @Published var receptiveScore = 0
  @Published var expressiveScore = 0
  @Published var isShowingSettings = false
  @Published var isMenuOpen = false
  @Published var mode: GameMode = .receptive
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
    self.hasSubmitted = true // avoid showing onboarding
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

  @UserDefault("maxWordLength", defaultValue: Int.max)
  var maxWordLength: Int {
    willSet {
      Words = AllWords.filter { $0.count <= newValue }
      self.playback.setNextWord()
      if !self.feedback.hasSubmitted {
        self.playback.hasPlayed = false
      }
      self.feedback.reset()
      self.objectWillChange.send()
    }
  }
}
