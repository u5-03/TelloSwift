//
//  TelloManager.swift
//  TelloSwiftTest
//  Copyright © 2020 yugo.sugiyama. All rights reserved.
//

import Foundation
import Network
import RxSwift

struct TelloConstants {
    static let ipAddress = "192.168.10.1"
    static let port: UInt16 = 8889
}

enum TelloCommands {
    case start
    case takeoff
    case land
    case emergency
    // Min: 20, Max: 500(cm)
    case left(x: Int)
    case right(x: Int)
    case forward(x: Int)
    case back(x: Int)
    case up(x: Int)
    case down(x: Int)

    // Min: 1, Max: 360(degree)
    case rotateRight(x: Int)
    case rotateLeft(x: Int)

    case flip(direction: TelloDirection)
}

extension TelloCommands {
    var asString: String {
        switch self {
        case .start: return "command"
        case .land: return "land"
        case .takeoff: return "takeoff"
        case .emergency: return "emergency"
        case .left(let x): return "left \(x)"
        case .right(let x): return "right \(x)"
        case .forward(let x): return "forward \(x)"
        case .back(let x): return "back \(x)"
        case .up(let x): return "up \(x)"
        case .down(let x): return "down \(x)"
        case .rotateRight(let x): return "cw \(x)"
        case .rotateLeft(let x): return "ccw \(x)"
        case .flip(let direction): return "flip \(direction.asString)"
        }
    }
}

enum TelloDirection {
    case left
    case right
    case forward
    case back

    var asString: String {
        switch self {
        case .left: return "l"
        case .right: return "r"
        case .forward: return "f"
        case .back: return "b"
        }
    }
}

class TelloManager {
    let connection = NWConnection(host: .init(TelloConstants.ipAddress), port: .init(integerLiteral: TelloConstants.port), using: .udp)

    init() {
        connection.stateUpdateHandler = { state in
            switch state {
            case .setup:
                print("Setup")
            case .waiting(let error):
                print(error)
            case .preparing:
                print("preparing")
            case .ready:
                print("ready")
            case .failed(let error):
                print(error)
            case .cancelled:
                print("cancelled")
            @unknown default:
                fatalError("Unknown error")
            }
        }
        connection.start(queue: .global())
    }

    func send(command: TelloCommands, completion: @escaping ((Result<String, Error>) -> Void)) {
        print("Commands: ", command.asString)
        let message = command.asString.data(using: .utf8)
        connection.receive(minimumIncompleteLength: 0, maximumLength: Int(Int32.max)) { (data, context, isComplete, error) in
                    if !isComplete, let error = error {
                        completion(.failure(error))
                    } else if let data = data, let message = String(data: data, encoding: .utf8) {
                        completion(.success(message))
                    } else {
                        print("Unknown error")
                    }
                }
        connection.send(content: message, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed({ error in
            if let error = error {
                completion(.failure(error))
            }
        }))
    }

    func send(command: TelloCommands) -> Single<String> {
        return Single<String>.create { [unowned self] single -> Disposable in
            self.send(command: command) { result in
                switch result {
                case .success(let message):
                    single(.success(message))
                case .failure(let error):
                    single(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func sends(parameters: (commands: [TelloCommands], interval: Int)) -> Observable<String> {
        let commandsObservables = parameters.commands.map(send)
            .map({ $0.asObservable().delay(.seconds(parameters.interval), scheduler: MainScheduler.instance) })
        return Observable.concat(commandsObservables)
    }

    func cancel() {
        connection.cancel()
    }
}
