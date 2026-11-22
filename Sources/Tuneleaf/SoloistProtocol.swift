import Foundation

struct SoloistEvent: Decodable {
    let type: String
    let loggedIn: Bool?
    let isActive: Bool?
    let deviceName: String?
    let status: String?
    let item: Item?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case type, status, item, message
        case loggedIn = "logged_in"
        case isActive = "is_active"
        case deviceName = "device_name"
    }

    struct Item: Decodable {
        let decorations: Decorations?
    }

    struct Decorations: Decodable {
        let identity: Identity?
        let creators: [Creator]?
    }

    struct Identity: Decodable {
        let name: String?
    }

    struct Creator: Decodable {
        let entity: Entity?
    }

    struct Entity: Decodable {
        let decorations: Decorations?
    }
}

struct PlayerState {
    var loggedIn = false
    var active = false
    var deviceName = ""
    var status = "idle"
    var title = ""
    var artist = ""

    mutating func apply(_ event: SoloistEvent) {
        switch event.type {
        case "auth_state":
            loggedIn = event.loggedIn ?? false
            active = event.isActive ?? false
            deviceName = event.deviceName ?? ""
            if !loggedIn {
                status = "idle"
                title = ""
                artist = ""
            }
        case "playback_state":
            status = event.status ?? "idle"
            active = event.isActive ?? active
            updateItem(event.item)
        case "track_changed":
            updateItem(event.item)
        case "playback_changed":
            if let status = event.status {
                self.status = status
            }
        case "device_changed":
            active = event.isActive ?? active
            deviceName = event.deviceName ?? deviceName
        default:
            break
        }
    }

    private mutating func updateItem(_ item: SoloistEvent.Item?) {
        title = item?.decorations?.identity?.name ?? ""
        artist = item?.decorations?.creators?
            .compactMap { $0.entity?.decorations?.identity?.name }
            .joined(separator: ", ") ?? ""
    }
}

struct SoloistCommand: Encodable {
    let type = "command"
    let command: String
    let uri: String?
}
