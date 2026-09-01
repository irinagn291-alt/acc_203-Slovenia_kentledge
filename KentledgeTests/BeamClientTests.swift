import XCTest
@testable import Kentledge

private struct ProbeDTO: Decodable {
    var tonnage: LooseTonnage
}

private actor ScriptedChannel: DockChannel {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func ping(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class BeamClientTests: XCTestCase {
    private let url = URL(string: "https://kentledge-beam.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let channel = ScriptedChannel(results: [
            .success((Data("{\"tonnage\":1}".utf8), http(200))),
        ])
        let client = BeamClient(channel: channel)
        _ = try await client.decodeManifest(ProbeDTO.self, from: url)
        let request = await channel.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), BeamClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(BeamClient.userAgent, "Kentledge/1.0 (iOS; +https://kentledge-beam.pro)")
        XCTAssertEqual(BeamClient.contactURL.absoluteString, "https://kentledge-beam.pro/contact-us")
    }

    func test_retriesTransientTransportOnce() async throws {
        let channel = ScriptedChannel(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"tonnage\":\"4.5\"}".utf8), http(200))),
        ])
        let client = BeamClient(channel: channel)
        let dto = try await client.decodeManifest(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.tonnage.tons, 4.5)
        let count = await channel.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let channel = ScriptedChannel(results: [
            .success((Data(), http(404))),
            .success((Data("{\"tonnage\":1}".utf8), http(200))),
        ])
        let client = BeamClient(channel: channel)
        do {
            _ = try await client.decodeManifest(ProbeDTO.self, from: url)
            XCTFail("expected vacant")
        } catch {
            XCTAssertEqual(error as? DockReply, .vacant)
        }
        let count = await channel.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsUnreadable() async {
        let channel = ScriptedChannel(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = BeamClient(channel: channel)
        do {
            _ = try await client.decodeManifest(ProbeDTO.self, from: url)
            XCTFail("expected unreadable")
        } catch {
            XCTAssertEqual(error as? DockReply, .unreadable)
        }
    }

    func test_statusZeroMapsToVacant() async {
        let channel = ScriptedChannel(results: [
            .success((Data("{\"status\":0}".utf8), http(200))),
        ])
        let client = BeamClient(channel: channel)
        do {
            _ = try await client.readSignal(from: url)
            XCTFail("expected vacant")
        } catch {
            XCTAssertEqual(error as? DockReply, .vacant)
        }
    }

    func test_looseTonnageAcceptsNumberAndString() throws {
        let number = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"tonnage\":12.5}".utf8))
        let string = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"tonnage\":\"12.5\"}".utf8))
        let missing = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"tonnage\":null}".utf8))
        XCTAssertEqual(number.tonnage.tons, 12.5)
        XCTAssertEqual(string.tonnage.tons, 12.5)
        XCTAssertNil(missing.tonnage.tons)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
