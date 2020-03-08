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

struct WordView: View {
  
  @State private var index = 0
  @State private var done = false
  private var timer: LoadingTimer
  private var images: [UIImage]
  private var onFinish: () -> Void
  
  init(_ word: String, onFinish: @escaping () -> Void, every: Double = 0.5) {
    let letters = Array(word).map { String($0).uppercased() }
    self.timer = LoadingTimer(every: every)
    self.images = letters.map { UIImage(named: $0)! }
    self.onFinish = onFinish
  }
  
  var body: some View {
    return Image(uiImage: self.images[index])
      .resizable()
      .frame(width: 100, height: 100, alignment: .center)
      .onReceive(
        self.timer.publisher,
        perform: { _ in
          self.index = self.index + 1
          if self.index >= self.images.count {
            self.timer.cancel()
            self.index = 0
            self.onFinish()
          }
      }
    )
      .onAppear { self.timer.start() }
      .onDisappear { self.timer.cancel() }
  }
}

struct ContentView: View {
  @State var alertIsVisible: Bool = false
  @State var speed = 5.0
  @State var wordFinished = false
  let minSpeed = 0.0
  let maxSpeed = 10.0
  
  var body: some View {
    VStack {
      Spacer()
      HStack {
        if !self.wordFinished {
          WordView("lauren",
                   onFinish: {() -> Void in
                    self.wordFinished = true
          })
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
