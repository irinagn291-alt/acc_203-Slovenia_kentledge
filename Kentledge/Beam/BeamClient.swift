import Foundation

/// Role: Beam. Typed hop failures. This product has no remote catalog.
enum DockReply: Error, Equatable, Sendable {
    case vacant
    case unreadable
    case seaState
    case cutShort
    case notHTTP
}

/// Role: Beam. Injected hop so tests never leave the process.
protocol DockChannel: Sendable {
    func ping(_ request: URLRequest) async throws -> (Data, URLResponse)
}

struct SessionChannel: DockChannel {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": BeamClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func ping(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Beam. Number or numeric string; missing stays nil. Never a domain field.
struct LooseTonnage: Sendable, Equatable, Decodable {
    var tons: Double?

    init(tons: Double?) {
        self.tons = tons
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.singleValueContainer()
        if box.decodeNil() {
            tons = nil
            return
        }
        if let number = try? box.decode(Double.self) {
            tons = number
            return
        }
        if let whole = try? box.decode(Int.self) {
            tons = Double(whole)
            return
        }
        if let text = try? box.decode(String.self) {
            tons = Double(text)
            return
        }
        tons = nil
    }
}

struct DockSignalDTO: Decodable, Sendable {
    var status: Int
}

/// Role: Beam. Owns the session. Contact URL is opened by Settings, not decoded here.
actor BeamClient {
    static let userAgent = "Kentledge/1.0 (iOS; +https://kentledge-beam.pro)"
    static let contactURL = URL(string: "https://kentledge-beam.pro/contact-us")!

    private let channel: any DockChannel

    init(channel: any DockChannel) {
        self.channel = channel
    }

    init() {
        self.channel = SessionChannel()
    }

    func decodeManifest<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await haul(ticket(for: url))
        do {
            return try JSONDecoder().decode(DTO.self, from: body)
        } catch is CancellationError {
            throw DockReply.cutShort
        } catch {
            throw DockReply.unreadable
        }
    }

    func readSignal(from url: URL) async throws -> Int {
        let dto = try await decodeManifest(DockSignalDTO.self, from: url)
        if dto.status == 0 {
            throw DockReply.vacant
        }
        return dto.status
    }

    private func ticket(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func haul(_ request: URLRequest) async throws -> Data {
        do {
            return try await hop(request)
        } catch let reply as DockReply {
            throw reply
        } catch is CancellationError {
            throw DockReply.cutShort
        } catch {
            if Self.cutShort(error) {
                throw DockReply.cutShort
            }
            guard Self.choppy(error) else { throw DockReply.seaState }
            do {
                return try await hop(request)
            } catch let reply as DockReply {
                throw reply
            } catch is CancellationError {
                throw DockReply.cutShort
            } catch {
                if Self.cutShort(error) { throw DockReply.cutShort }
                throw DockReply.seaState
            }
        }
    }

    private func hop(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (body, reply) = try await channel.ping(request)
        guard let http = reply as? HTTPURLResponse else {
            throw DockReply.notHTTP
        }
        if http.statusCode == 404 {
            throw DockReply.vacant
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw DockReply.seaState
        }
        return body
    }

    private static func choppy(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cutShort(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
