import Foundation

@MainActor
final class SoloistClient: ObservableObject {
    enum Connection {
        case disconnected, connecting, connected
    }

    @Published private(set) var connection: Connection = .disconnected
    @Published private(set) var state = PlayerState()
    @Published var errorMessage: String?

    private var socket: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var connectionID = UUID()

    func connect(port: String) {
        guard let number = Int(port), (1...65535).contains(number) else {
            errorMessage = "Enter a port between 1 and 65535."
            return
        }
        disconnect()
        errorMessage = nil
        connection = .connecting
        let id = UUID()
        connectionID = id
        let url = URL(string: "ws://127.0.0.1:\(number)")!
        let socket = URLSession.shared.webSocketTask(with: url)
        self.socket = socket
        socket.resume()
        receiveTask = Task { await receive(from: socket, id: id) }
    }

    func disconnect() {
        connectionID = UUID()
        receiveTask?.cancel()
        receiveTask = nil
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        connection = .disconnected
        state = PlayerState()
    }

    func send(_ command: String, uri: String? = nil) {
        guard connection == .connected, state.loggedIn, let socket else {
            errorMessage = "Connect and pair Spotify Soloist before sending commands."
            return
        }
        let id = connectionID
        Task {
            do {
                let data = try JSONEncoder().encode(SoloistCommand(command: command, uri: uri))
                try await socket.send(.string(String(decoding: data, as: UTF8.self)))
            } catch {
                if id == connectionID {
                    errorMessage = "Could not send \(command): \(error.localizedDescription)"
                }
            }
        }
    }

    private func receive(from socket: URLSessionWebSocketTask, id: UUID) async {
        do {
            while !Task.isCancelled {
                let message = try await socket.receive()
                guard id == connectionID else { return }
                let data: Data
                switch message {
                case .string(let text):
                    data = Data(text.utf8)
                case .data(let bytes):
                    data = bytes
                @unknown default:
                    errorMessage = "Received an unsupported WebSocket message."
                    continue
                }
                do {
                    let event = try JSONDecoder().decode(SoloistEvent.self, from: data)
                    if event.type == "auth_state" {
                        connection = .connected
                    }
                    if event.type == "error" {
                        errorMessage = event.message ?? "Spotify Soloist reported an unspecified error."
                    } else {
                        state.apply(event)
                    }
                } catch {
                    errorMessage = "Could not read a Spotify Soloist event: \(error.localizedDescription)"
                }
            }
        } catch {
            guard id == connectionID, !Task.isCancelled else { return }
            disconnect()
            errorMessage = "Connection to Spotify Soloist lost: \(error.localizedDescription)"
        }
    }
}
