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

struct MainDisplayIcon: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding()
      .font(.system(size: 120))
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
  private let nextWordDelay = 1.0 // seconds
  private var words = [String]()

  init() {
    if let path = Bundle.main.path(forResource: "words", ofType: "json") {
      do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        if let jsonResult = jsonResult as? [String] {
          self.words = jsonResult
        }
      } catch {
        print("Could not parse words.json")
      }
    }
    // XXX Setting state variable in init: https://stackoverflow.com/a/60028709/1157536
    self._currentWord = State<String>(initialValue: self.words.randomElement()!)
    self._playTimer = State<LoadingTimer?>(initialValue: self.getTimer())
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

  private var isPlaying: Bool {
    !self.hasPlayed || self.waitingForNextWord
  }

  private func getTimer() -> LoadingTimer {
    let every = self.numerator / max(self.speed, 1.0)
    return LoadingTimer(every: every)
  }

  private func resetTimer() {
    self.playTimer!.cancel()
    self.playTimer = self.getTimer()
  }

  private func handleReplay() {
    self.resetWord()
  }

  private func resetWord() {
    self.letterIndex = 0
    self.hasPlayed = false
    self.showAnswer = false
  }

  private func handleNextWord() {
    self.answer = ""
    self.currentWord = self.words.randomElement()!
    self.submittedValidAnswer = false
    self.waitingForNextWord = true
    self.showAnswer = false
    self.delayTimer = Timer.scheduledTimer(withTimeInterval: self.nextWordDelay, repeats: false) { _ in
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
    self.handleStop()
    self.showAnswer = true
    if self.isAnswerValid {
      self.submittedValidAnswer = true
      self.score += 1
    }
  }

  private func renderCheckButton() -> some View {
    Button(action: self.handleSubmit) {
      Image(systemName: "checkmark").modifier(IconButton())
    }.disabled(self.answerTrimmed.isEmpty)
  }

  var body: some View {
    VStack {
      /* Score display */
      HStack {
        Spacer()
        HStack {
          Text("Score").bold()
          Spacer()
          Text(String(self.score))
        }.padding(.horizontal, 10)
          .padding(.vertical, 2)
          .background(Color.green)
          .foregroundColor(Color.white)
          .cornerRadius(8)
          .frame(maxWidth: 150)
        Spacer()
      }
      Spacer()

      /* Main display */
      HStack {
        if self.hasPlayed {
          if self.showAnswer || self.submittedValidAnswer {
            if self.submittedValidAnswer {
              VStack {
                Text(self.currentWord.uppercased()).font(.title)
                Image(systemName: "checkmark.circle")
                  .modifier(MainDisplayIcon())
                  .foregroundColor(Color.green)
              }

            } else {
              VStack {
                Text("Try again").font(.callout)
                Image(systemName: "xmark.circle")
                  .modifier(MainDisplayIcon())
                  .foregroundColor(Color.red)
              }
            }
          } else if self.waitingForNextWord {
            Text("*").padding().font(.system(size: 48))
          }
        } else {
          Image(uiImage: self.images[self.letterIndex])
            .resizable()
            .frame(width: 75, height: 100)
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
      Spacer()

      /* Speed control */
      VStack {
        HStack {
          Image(systemName: "tortoise").foregroundColor(.gray)
          Slider(value: self.$speed, in: self.minSpeed ... self.maxSpeed, step: 1)
            .disabled(!self.hasPlayed)
          Image(systemName: "hare").foregroundColor(.gray)
        }
        HStack {
          Text("Speed: \(String(Int(self.speed.rounded())))").font(.system(size: 14))
          Spacer()
        }
      }.padding(.top, 30)

      /* Answer input */
      HStack {
        FocusableTextField(
          text: $answer,
          isFirstResponder: true,
          placeholder: "WORD",
          textFieldShouldReturn: { _ in
            if self.submittedValidAnswer {
              self.handleNextWord()
            } else {
              self.handleSubmit()
            }
            return true
          },
          modifyTextField: { textField in
            textField.borderStyle = .roundedRect
            textField.autocapitalizationType = .allCharacters
            textField.autocorrectionType = .no
            textField.returnKeyType = .go
            textField.keyboardType = .asciiCapable
            textField.font = .monospacedSystemFont(ofSize: 18.0, weight: .regular)
            return textField
          }
        )
        .frame(width: 300, height: 30)
        .opacity(self.submittedValidAnswer ? 0 : 1)
      }

      /* Word controls */
      HStack {
        if !self.isPlaying {
          // TODO: change this to "Reveal"
          if !self.submittedValidAnswer {
            Button(action: self.handleNextWord) {
              Text("Skip")
            }
          } else {
            // Placeholder to maintain spacing
            // TODO: Is there a better way to do this?
            Button(action: self.handleNextWord) {
              Text("Skip")
            }.hidden()
          }
          Spacer()
          Button(action: self.handleReplay) {
            Image(systemName: "play.fill").modifier(IconButton())
          }.offset(x: 10)
          Spacer()
        } else {
          // TODO: Is there a better way to do this?
          Button(action: {}) {
            Text("Skip")
          }.hidden()
          Spacer()
          Button(action: self.handleStop) {
            Image(systemName: "stop.fill").modifier(IconButton()).foregroundColor(.red)
          }.offset(x: 10)
          Spacer()
        }
        if self.submittedValidAnswer {
          Button(action: self.handleNextWord) {
            Image(systemName: "arrow.right.to.line").modifier(IconButton())
          }
        } else {
          self.renderCheckButton()
        }
      }
    }
    // Move the current UI up when the keyboard is active
    .padding(.bottom, keyboard.currentHeight)
    .padding(.top, 10)
    .padding(.horizontal, 40)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
