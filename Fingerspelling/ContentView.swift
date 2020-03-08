//
//  ContentView.swift
//  Fingerspelling
//
//  Created by Steven Loria on 3/7/20.
//

import SwiftUI
import Combine


// XXX: Complicated implementation of an animated image
//   since there doesn't seem to be a better way to do this in
//   SwiftUI yet: https://stackoverflow.com/a/57749621/1157536
class LoadingTimer {
  
  var publisher: Timer.TimerPublisher
  private var timerCancellable: Cancellable?
  
  init (every: Double) {
    self.publisher = Timer.publish(every: every, on: .main, in: .default)
    self.timerCancellable = nil
  }
  
  func start() {
    self.timerCancellable = publisher.connect()
  }
  
  func cancel() {
    self.timerCancellable?.cancel()
  }
}

struct ContentView: View {
  @State var alertIsVisible: Bool = false
  @State var speed = 5.0
  @State var wordFinished = false
  @State var letterIndex = 0
  @State var timer: LoadingTimer = LoadingTimer(every: 0.5)
  
  var images: [UIImage]

  
  let minSpeed = 0.0
  let maxSpeed = 10.0
  
  init() {
    let letters = Array("lauren").map { String($0).uppercased() }
    self.images = letters.map { UIImage(named: $0)! }
  }
  
  func resetTimer() {
    self.timer.cancel()
    self.timer = LoadingTimer(every: 0.5)
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
      VStack {
        HStack {
          Text("Slow")
          Slider(value: self.$speed, in: self.minSpeed...self.maxSpeed)
          Text("Fast")
        }
        Button(action: {
          self.speed = (self.maxSpeed - self.minSpeed) / 2
        }) {
          Text("Reset speed")
        }
      }
      .padding(.horizontal, 40)
      .padding(.vertical, 30)
      
      HStack {
        if self.wordFinished {
          Button(action: {
            self.letterIndex = 0
            self.wordFinished = false
          }) {
            Text("Replay")
          }
          Button(action: {
            self.alertIsVisible = true
          }) {
            Text("Next word")
          }
          .alert(isPresented: $alertIsVisible) { () -> Alert in
            return Alert(
              title: Text("TODO"),
              message: Text("show next word")
            )
          }
        } else {
          // Placeholder to maintain spacing
          Button(action: {}) { Text("Replay")}.hidden()
        }
      }
      .padding(.bottom, 20)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
