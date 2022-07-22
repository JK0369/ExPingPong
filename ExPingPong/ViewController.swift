//
//  ViewController.swift
//  ExPingPong
//
//  Created by 김종권 on 2022/07/22.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
  var pingPong: PingPong?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.pingPong = PingPong()
    self.pingPong?.runPingPong {
      print("lost connection")
    }
  }
}

class PingPong {
  private enum Const {
    static let timeOutSeconds = 5
    static let throttleSeconds = timeOutSeconds - 1
  }
  
  private var disposeBag = DisposeBag()
  private var timeoutDisposeBag = DisposeBag()
  
  func runPingPong(_ completion: @escaping () -> ()) {
    self.sendPing { completion() }
  }
  
  private func sendPing(_ completion: @escaping () -> ()) {
    API.requestPing()
      .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
      .throttle(.seconds(Const.throttleSeconds), scheduler: ConcurrentDispatchQueueScheduler.init(qos: .background))
      .subscribe(with: self, onNext: { ss, _ in
        print(123)
        ss.receivePong { completion() }
      })
      .disposed(by: self.disposeBag)
    
    Observable<Int>
      .timer(.seconds(Const.timeOutSeconds), scheduler: ConcurrentDispatchQueueScheduler.init(qos: .background))
      .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
      .subscribe(onNext: { _ in
        completion()
      })
      .disposed(by: self.timeoutDisposeBag)
  }
  
  private func receivePong(_ completion: @escaping () -> ()) {
    print("receive pong")
    self.timeoutDisposeBag = DisposeBag()
    self.sendPing { completion() }
  }
}

enum API {
  static func requestPing() -> Observable<Int> {
    .create { observer -> Disposable in
      print("send ping")
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        observer.onNext(Int.random(in: 0...10))
      }
      return Disposables.create()
    }
  }
}
