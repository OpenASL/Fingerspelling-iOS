//
//  ContentView.swift
//  Fingerspelling
//
//  Created by Steven Loria on 3/7/20.
//

import SwiftUI

struct AnimatedImage: UIViewRepresentable {
  private var word: String
  
  init (_ word: String) {
    self.word = word
  }
  func makeUIView(context: Self.Context) -> UIImageView {
    let imageView = UIImageView(image: renderWord(word))
    imageView.animationRepeatCount = 1
    return imageView
  }
  
  func renderWord(_ word: String) -> UIImage {
    var images = [UIImage]()
    for letter in Array(word) {
      let image = UIImage(named: String(letter).uppercased())!
      images.append(image)
    }
    return UIImage.animatedImage(with: images, duration: 5.0)!
  }
  
  func updateUIView(_ uiView: UIImageView, context: UIViewRepresentableContext<AnimatedImage>) {
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
        AnimatedImage("LAUREN")
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
