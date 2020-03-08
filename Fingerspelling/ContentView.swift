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

struct ContentView: View {
  @State private var alertIsVisible: Bool = false
  @State private var speed = 5.0
  @State private var wordFinished = false
  @State private var letterIndex = 0
  @State private var answer: String = ""
  @State private var showValidation: Bool = false
  @State private var timer: LoadingTimer = LoadingTimer(every: 0.5)
  @ObservedObject private var keyboard = KeyboardResponder()

  private var images: [UIImage]
  private let numerator = 2.0
  private let minSpeed = 0.0
  private let maxSpeed = 10.0

  private var isAnswerValid: Bool {
    let trimmedString = self.answer.trimmingCharacters(in: .whitespaces).lowercased()
    return trimmedString == "test"
  }

  init() {
    let letters = Array("lauren").map { String($0).uppercased() }
    self.images = letters.map { UIImage(named: $0)! }
  }

  func getTimer() -> LoadingTimer {
    let every = self.numerator / max(self.speed, 1)
    return LoadingTimer(every: every)
  }

  func resetTimer() {
    self.timer.cancel()
    self.timer = self.getTimer()
  }
  
  func handleReplay() {
    self.letterIndex = 0
    self.wordFinished = false
  }
  
  func handleNextWord() {
    self.alertIsVisible = true
    self.showValidation = false
    self.answer = ""
  }
  
  func handleResetSpeed() {
    self.speed = (self.maxSpeed - self.minSpeed) / 2
  }
  
  func handleCheck() {
    self.showValidation = true
  }

  var body: some View {
    VStack {
      Spacer()
      HStack {
        if !self.wordFinished {
          Image(uiImage: self.images[self.letterIndex])
            .resizable()
            .frame(width: 100, height: 100, alignment: .center)
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
      .padding(.horizontal, 100)
      Spacer()
      HStack {
        if self.showValidation {
          TextField("Answer", text: $answer).border(self.isAnswerValid ? Color.green : Color.red)
        } else {
          TextField("Answer", text: $answer)
        }
        Spacer()
        Button(action: self.handleCheck) {
          Text("Check")
        }
      }.padding(.top, 20)

      VStack {
        HStack {
          Text("Slow")
          Slider(value: self.$speed, in: self.minSpeed ... self.maxSpeed)
          Text("Fast")
        }
        Button(action: self.handleResetSpeed) {
          Text("Reset speed")
        }
      }.padding(.vertical, 30)

      HStack {
        if self.wordFinished {
          Button(action: self.handleReplay) {
            Text("Replay")
          }
          .alert(isPresented: $alertIsVisible) { () -> Alert in
            Alert(
              title: Text("TODO"),
              message: Text("show next word")
            )
          }
          Button(action: self.handleNextWord) {
            Text("Next word")
          }
          .alert(isPresented: $alertIsVisible) { () -> Alert in
            Alert(
              title: Text("TODO"),
              message: Text("show next word")
            )
          }
        } else {
          // Placeholder to maintain spacing while buttons are hidden
          Button(action: {}) { Text("Replay") }.hidden()
        }
      }
    }
    // Move the current UI up when the keyboard is active
    .padding(.bottom, keyboard.currentHeight)
    .padding(.vertical, 20)
    .padding(.horizontal, 40)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
