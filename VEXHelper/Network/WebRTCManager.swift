import Foundation
import WebRTC

protocol WebRTCManagerDelegate: AnyObject {
    func webRTCManager(_ manager: WebRTCManager, didOpenDataChannel channel: RTCDataChannel)
    func webRTCManager(_ manager: WebRTCManager, didReceiveMessage message: String)
}

class WebRTCManager: NSObject {
    static let shared = WebRTCManager()

    var peerConnection: RTCPeerConnection?
    var dataChannel: RTCDataChannel?
    weak var delegate: WebRTCManagerDelegate?
    
    private let peerConnectionFactory: RTCPeerConnectionFactory
    
    override init() {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        self.peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
        super.init()
    }
    
    func createPeerConnection() {
        let config = RTCConfiguration()
        // Use public STUN server for ICE
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = peerConnectionFactory.peerConnection(with: config, constraints: constraints, delegate: self)
    }
    
    func handleSignalingMessage(_ jsonString: String, from connection: WebSocketConnection) {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let type = dict["type"] as? String else { return }
        
        if type == "sdp", let sdpString = dict["sdp"] as? String, let sdpTypeString = dict["sdpType"] as? String {
            let sdpType: RTCSdpType = sdpTypeString == "offer" ? .offer : .answer
            let sessionDescription = RTCSessionDescription(type: sdpType, sdp: sdpString)
            
            if peerConnection == nil {
                createPeerConnection()
            }
            
            peerConnection?.setRemoteDescription(sessionDescription, completionHandler: { error in
                if let error = error {
                    print("WebRTC Error: Failed to set remote description - \(error.localizedDescription)")
                    return
                }
                
                if sdpType == .offer {
                    self.peerConnection?.answer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), completionHandler: { answerDesc, answerError in
                        if let answerError = answerError {
                            print("WebRTC Error: Failed to create answer - \(answerError.localizedDescription)")
                            return
                        }
                        
                        guard let answer = answerDesc else {
                            print("WebRTC Error: Answer description is nil")
                            return
                        }
                        
                        self.peerConnection?.setLocalDescription(answer, completionHandler: { localError in
                            if let localError = localError {
                                print("WebRTC Error: Failed to set local description - \(localError.localizedDescription)")
                                return
                            }
                            
                            // Send answer back via WS
                            let answerDict: [String: Any] = [
                                "type": "sdp",
                                "sdpType": "answer",
                                "sdp": answer.sdp
                            ]
                            if let data = try? JSONSerialization.data(withJSONObject: answerDict),
                               let str = String(data: data, encoding: .utf8) {
                                connection.send(string: str)
                            }
                        })
                    })
                }
            })
            
        } else if type == "ice", let candidate = dict["candidate"] as? String,
                  let sdpMid = dict["sdpMid"] as? String,
                  let sdpMLineIndex = dict["sdpMLineIndex"] as? Int32 {
            let iceCandidate = RTCIceCandidate(sdp: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
            peerConnection?.add(iceCandidate)
        }
    }
    
    func sendData(_ message: String) {
        guard let dataChannel = dataChannel, dataChannel.readyState == .open else {
            // Fallback to WebSocket if DataChannel is not ready yet
            LocalNetworkService.shared.broadcast(message: message)
            return
        }
        guard let data = message.data(using: .utf8) else { return }
        let buffer = RTCDataBuffer(data: data, isBinary: false)
        dataChannel.sendData(buffer)
    }
    
    func closeConnection() {
        dataChannel?.close()
        peerConnection?.close()
        dataChannel = nil
        peerConnection = nil
    }
}

extension WebRTCManager: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        if newState == .failed || newState == .disconnected || newState == .closed {
            closeConnection()
        }
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // Send ICE candidate back via WS
        let iceDict: [String: Any] = [
            "type": "ice",
            "candidate": candidate.sdp,
            "sdpMid": candidate.sdpMid ?? "",
            "sdpMLineIndex": candidate.sdpMLineIndex
        ]
        if let data = try? JSONSerialization.data(withJSONObject: iceDict),
           let str = String(data: data, encoding: .utf8) {
            LocalNetworkService.shared.broadcast(message: str)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.dataChannel = dataChannel
        dataChannel.delegate = self
        DispatchQueue.main.async {
            self.delegate?.webRTCManager(self, didOpenDataChannel: dataChannel)
        }
    }
}

extension WebRTCManager: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {}
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if !buffer.isBinary, let message = String(data: buffer.data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.delegate?.webRTCManager(self, didReceiveMessage: message)
            }
        }
    }
}
