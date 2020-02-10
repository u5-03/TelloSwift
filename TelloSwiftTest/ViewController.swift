//
//  ViewController.swift
//  TelloSwiftTest
//  Copyright © 2020 yugo.sugiyama. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var setupButton: UIButton!
    @IBOutlet weak var takeOffButton: UIButton!
    @IBOutlet weak var landButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var emergencyButton: UIButton!
    @IBOutlet weak var pattern1Button: UIButton!
    @IBOutlet weak var pattern2Button: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    private let resultRelay = PublishRelay<String>()
    private let disposeBag = DisposeBag()
    private let tello = TelloManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupButton.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map({ _ in .start })
            .flatMap(tello.send)
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
        takeOffButton.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map({ _ in .takeoff })
            .flatMap(tello.send)
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
        landButton.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map({ _ in .land })
            .flatMap(tello.send)
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
        flipButton.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map({ _ in .flip(direction: .forward) })
            .flatMap(tello.send)
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
        rightButton.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map({ _ in .right(x: 100) })
            .flatMap(tello.send)
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
        leftButton.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map({ _ in .left(x: 100) })
            .flatMap(tello.send)
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
        emergencyButton.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map({ _ in .emergency })
            .flatMap(tello.send)
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
        pattern1Button.rx.tap.throttle(.seconds(2), scheduler: MainScheduler.instance)
            .map({ _ -> [TelloCommands] in [.takeoff, .up(x: 30), .down(x: 30), .left(x: 100), .right(x: 100), .flip(direction: .forward), .flip(direction: .back), .land] })
            .map({ ($0, 1) })
            .flatMap(tello.sends)
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
        pattern2Button.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map({ _ in .up(x: 100) })
            .flatMap(tello.send)
            .bind(to: resultRelay)
            .disposed(by: disposeBag)
        cancelButton.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] in
                self.tello.cancel()
            })
            .disposed(by: disposeBag)
        resultRelay.asObservable()
            .subscribe(onNext: { message in
                print("Message: ", message)
            }, onError: { (error) in
                print("Error: ", error)
            })
            .disposed(by: disposeBag)
    }
}

