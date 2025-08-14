import Foundation
import WebRTC

final class LLMClient: NSObject {
    private var pc: RTCPeerConnection!
    private var dataChannel: RTCDataChannel?
    private let factory = RTCPeerConnectionFactory()
    private let signalingURL: URL
    private let stunURLs: [String]
    private let turnURL: String?
    private let turnUser: String?
    private let turnPass: String?
    private var t0: CFAbsoluteTime = 0

    init(signalingEndpoint: String,
         stunURLs: [String] = ["stun:stun.l.google.com:19302"],
         turnURL: String? = nil, turnUser: String? = nil, turnPass: String? = nil) {
        self.signalingURL = URL(string: signalingEndpoint + "/signaling/offer")!
        self.stunURLs = stunURLs
        self.turnURL = turnURL
        self.turnUser = turnUser
        self.turnPass = turnPass
        super.init()
        setupPeer()
    }

    func connect(completion: @escaping (Result<Void, Error>) -> Void) {
        let dcConfig = RTCDataChannelConfiguration()
        dcConfig.isOrdered = true
        self.dataChannel = pc.dataChannel(forLabel: "llm", configuration: dcConfig)
        self.dataChannel?.delegate = self

        pc.offer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)) { [weak self] sdp, err in
            guard let self = self, let sdp = sdp else {
                completion(.failure(err ?? NSError(domain: "offer", code: -1))); return
            }
            self.pc.setLocalDescription(sdp) { [weak self] err in
                guard let self = self else { return }
                if let err = err { completion(.failure(err)); return }
                var req = URLRequest(url: self.signalingURL)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.httpBody = try? JSONSerialization.data(withJSONObject: ["sdp": sdp.sdp])
                URLSession.shared.dataTask(with: req) { data, _, err in
                    if let err = err { completion(.failure(err)); return }
                    guard let data = data,
                        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let sdpStr = obj["sdp"] as? String else {
                        completion(.failure(NSError(domain: "bad_answer", code: -2))); return
                    }
                    let answer = RTCSessionDescription(type: .answer, sdp: sdpStr)
                    self.pc.setRemoteDescription(answer) { err in
                        if let err = err { completion(.failure(err)); return }
                        completion(.success(()))
                    }
                }.resume()
            }
        }
    }

    func sendChat(prompt: String, model: String = "llama3.1:8b-instruct-q4_K_M") {
        let msg: [String: Any] = ["op":"chat", "model": model, "prompt": prompt, "stream": true]
        let data = try! JSONSerialization.data(withJSONObject: msg)
        let buffer = RTCDataBuffer(data: data, isBinary: false)
        t0 = CFAbsoluteTimeGetCurrent()
        dataChannel?.sendData(buffer)
    }

    private func setupPeer() {
        let config = RTCConfiguration()
        var iceServers: [RTCIceServer] = [RTCIceServer(urlStrings: stunURLs)]
        if let turnURL, let turnUser, let turnPass {
            iceServers.append(RTCIceServer(urlStrings: [turnURL], username: turnUser, credential: turnPass))
        }
        config.iceServers = iceServers
        config.sdpSemantics = .unifiedPlan
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement":"true"])
        self.pc = factory.peerConnection(with: config, constraints: constraints, delegate: self)
    }
}

extension LLMClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.dataChannel = dataChannel
        self.dataChannel?.delegate = self
    }
}

extension LLMClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {}
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        guard let obj = try? JSONSerialization.jsonObject(with: buffer.data) as? [String: Any],
              let op = obj["op"] as? String else { return }
        switch op {
        case "delta":
            if let content = obj["content"] as? String {
                if t0 != 0 { // 初トークン計測
                    let ttft = (CFAbsoluteTimeGetCurrent() - t0) * 1000
                    print(String(format:"[TTFT] %.0f ms", ttft))
                    t0 = 0
                }
                print(content, terminator: "")
            }
        case "done":
            print("\n[done]")
        case "error":
            print("[error]", obj["error"] ?? "")
        default: break
        }
    }
}
