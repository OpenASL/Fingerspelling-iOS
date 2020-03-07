//
//  ContentView.swift
//  Fingerspelling
//
//  Created by Steven Loria on 3/7/20.
//

import SwiftUI
import Combine

func renderWord(_ w: Array<String>) -> UIImage {
  var images = [UIImage]()
  for letter in w {
    images.append(UIImage(named: letter)!)
  }
  return UIImage.animatedImage(with: images, duration: 1.0)!
}


class LoadingTimer {
  
  let publisher = Timer.publish(every: 0.1, on: .main, in: .default)
  private var timerCancellable: Cancellable?
  
  init () {
    self.timerCancellable = nil
  }
  
  func start() {
    self.timerCancellable = publisher.connect()
  }
  
  func cancel() {
    self.timerCancellable?.cancel()
  }
}

struct LoadingView: View {
  
  @State private var index = 0
  
  private let images = ["S", "T", "E", "V", "E"].map { UIImage(named: $0)! }
  private var timer = LoadingTimer()
  
  var body: some View {
    
    return Image(uiImage: images[index])
      .resizable()
      .frame(width: 100, height: 100, alignment: .center)
      .onReceive(
        timer.publisher,
        perform: { _ in
          self.index = self.index + 1
          if self.index >= self.images.count { self.index = 0 }
      }
    )
      .onAppear { self.timer.start() }
      .onDisappear { self.timer.cancel() }
  }
}

struct ContentView: View {
  @State var alertIsVisible: Bool = false
  @State var speed = 5.0
  let minSpeed = 0.0
  let maxSpeed = 10.0
  
  var body: some View {
    VStack {
      Spacer()
      HStack {
        LoadingView()
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
