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

struct FullWidthButton: ViewModifier {
  var color: Color = Color.blue

  func body(content: Content) -> some View {
    content
      .padding()
      .font(.system(size: 24))
      .offset(x: 10)
      .frame(minWidth: 0, maxWidth: .infinity)
      .overlay(
        RoundedRectangle(cornerRadius: 40)
          .stroke(self.color, lineWidth: 1)
      )
      .foregroundColor(self.color)
  }
}

struct ContentView: View {
  @State private var showAnswer: Bool = false
  @State private var speed = 3.0
  @State private var hasPlayed = true
  @State private var letterIndex = 0
  @State private var answer: String = ""
  @State private var playTimer: LoadingTimer? = nil
  @State private var delayTimer: Timer? = nil
  @State private var currentWord = ""
  @State private var score = 0
  @State private var waitingForNextWord: Bool = false
  @State private var submittedValidAnswer: Bool = false
  @ObservedObject private var keyboard = KeyboardResponder()

  private let numerator = 2.0 // Higher value = slower speeds
  private let minSpeed = 1.0
  private let maxSpeed = 11.0
  private let postSubmitDelay = 2.0 // seconds
  private let nextWordDelay = 1.0 // seconds
  private var words = [String]()

  init() {
    // XXX Setting state variable in init: https://stackoverflow.com/a/60028709/1157536
    self._currentWord = State<String>(initialValue: Words.randomElement()!)
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
    !self.hasPlayed || self.waitingForNextWord
  }

  var body: some View {
    VStack {
      HStack {
        self.createSpeedDisplay()
        Spacer()
        self.createScoreDisplay()
      }
      Divider().padding(.bottom, 10)

      HStack {
        self.createAnswerInput()
        Spacer()
        // TODO: Make this reveal
        Button(action: self.handleNextWord) {
          Text("Skip").font(.system(size: 14))
        }.disabled(self.submittedValidAnswer)
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
      Text(String(Int(self.speed))).font(.system(size: 14))
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
    HStack {
      if self.hasPlayed {
        if self.showAnswer || self.submittedValidAnswer {
          if self.submittedValidAnswer {
            VStack {
              Text(self.currentWord.uppercased())
                .font(.title)
                .allowsTightening(true)
                .minimumScaleFactor(0.8)
                .scaledToFill()
              Image(systemName: "checkmark.circle")
                .modifier(MainDisplayIcon())
                .foregroundColor(Color.green)
            }

          } else {
            VStack {
              Image(systemName: "xmark.circle")
                .modifier(MainDisplayIcon())
                .foregroundColor(Color.red)
            }
          }
        }
      } else {
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
                self.hasPlayed = true
              }
            }
          )
          .onAppear {
            self.resetTimer()
            self.playTimer!.start()
          }
          .onDisappear { self.resetTimer() }
      }
    }.frame(width: 100, height: 150)
  }

  private func createSpeedControl() -> some View {
    HStack {
      Image(systemName: "tortoise").foregroundColor(.gray)
      Slider(value: self.$speed, in: self.minSpeed ... self.maxSpeed, step: 1)
        .disabled(!self.hasPlayed)
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
          return textField
        }
      )
      .frame(width: 275, height: 30)
      .opacity(self.submittedValidAnswer ? 0 : 1)
    }
  }

  private func createControls() -> some View {
    HStack {
      if !self.isPlaying {
        Button(action: self.handleReplay) {
          Image(systemName: "play.fill")
            .modifier(FullWidthButton())
        }.disabled(self.submittedValidAnswer)
      } else {
        Button(action: self.handleStop) {
          Image(systemName: "stop.fill").modifier(FullWidthButton())
        }
      }
    }
  }

  private func createCheckButton() -> some View {
    Button(action: self.handleSubmit) {
      Image(systemName: "checkmark").modifier(IconButton())
    }.disabled(self.answerTrimmed.isEmpty || self.submittedValidAnswer)
  }

  private func getTimer() -> LoadingTimer {
    let every = self.numerator / max(self.speed, 1.0)
    return LoadingTimer(every: every)
  }

  private func resetTimer() {
    self.playTimer!.cancel()
    self.playTimer = self.getTimer()
  }

  private func resetWord() {
    self.letterIndex = 0
    self.hasPlayed = false
    self.showAnswer = false
  }

  private func handleReplay() {
    self.resetWord()
  }

  private func handleNextWord() {
    self.answer = ""
    self.currentWord = Words.randomElement()!
    self.submittedValidAnswer = false
    self.waitingForNextWord = true
    self.showAnswer = false
    self.delayTimer = delayFor(self.nextWordDelay) {
      self.resetWord()
      self.waitingForNextWord = false
    }
  }

  private func handleStop() {
    self.delayTimer?.invalidate()
    self.resetTimer()
    self.resetWord()
    self.waitingForNextWord = false
    self.hasPlayed = true
  }

  private func handleSubmit() {
    // Prevent multiple submissions from pressing "return" key
    if self.submittedValidAnswer {
      return
    }
    self.handleStop()
    self.showAnswer = true
    if self.isAnswerValid {
      self.submittedValidAnswer = true
      self.score += 1
      delayFor(self.postSubmitDelay) {
        self.handleNextWord()
      }
    } else {
      delayFor(self.postSubmitDelay) {
        self.showAnswer = false
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
