import Darwin
import Foundation

enum AquaAutomationError: LocalizedError {
    case invalidSocketPath
    case connectFailed(String)
    case writeFailed(String)
    case readFailed(String)
    case emptyResponse
    case invalidResponse
    case commandFailed(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidSocketPath:
            "The Aqua automation socket path is too long."
        case let .connectFailed(message):
            "Could not connect to Aqua Voice: \(message)"
        case let .writeFailed(message):
            "Could not send a command to Aqua Voice: \(message)"
        case let .readFailed(message):
            "Could not read Aqua Voice's response: \(message)"
        case .emptyResponse:
            "Aqua Voice closed the automation connection."
        case .invalidResponse:
            "Aqua Voice returned an invalid automation response."
        case let .commandFailed(code, message):
            "Aqua Voice rejected the command (\(code)): \(message)"
        }
    }
}

struct AquaAutomationClient {
    let socketPath: String

    init(socketPath: String? = nil) {
        self.socketPath = socketPath ?? Self.makeDefaultSocketPath()
    }

    func ping() throws {
        _ = try request(command: "ping")
    }

    func setLanguage(_ languageCode: String) throws {
        _ = try request(
            command: "settings.set",
            params: ["key": "language", "value": languageCode]
        )
    }

    func removeStaleSocket() throws {
        guard FileManager.default.fileExists(atPath: socketPath) else { return }
        try FileManager.default.removeItem(atPath: socketPath)
    }

    @discardableResult
    func request(
        command: String,
        params: [String: Any]? = nil
    ) throws -> [String: Any] {
        let descriptor = try connectSocket()
        defer { Darwin.close(descriptor) }

        let id = UUID().uuidString
        var payload: [String: Any] = ["id": id, "command": command]
        if let params { payload["params"] = params }

        var data = try JSONSerialization.data(withJSONObject: payload)
        data.append(0x0A)
        try writeAll(data, to: descriptor)

        let responseData = try readLine(from: descriptor)
        guard
            let object = try JSONSerialization.jsonObject(
                with: responseData
            ) as? [String: Any],
            object["id"] as? String == id,
            let ok = object["ok"] as? Bool
        else {
            throw AquaAutomationError.invalidResponse
        }

        if ok {
            return object["result"] as? [String: Any] ?? [:]
        }

        let error = object["error"] as? [String: Any]
        throw AquaAutomationError.commandFailed(
            code: error?["code"] as? String ?? "unknown",
            message: error?["message"] as? String ?? "Unknown error"
        )
    }

    private func connectSocket() throws -> Int32 {
        try validateSocketIfPresent()
        let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            throw AquaAutomationError.connectFailed(lastError())
        }
        do {
            try configure(descriptor: descriptor)
        } catch {
            Darwin.close(descriptor)
            throw error
        }

        var address = sockaddr_un()
        let pathBytes = Array(socketPath.utf8CString)
        let capacity = MemoryLayout.size(ofValue: address.sun_path)
        guard pathBytes.count <= capacity else {
            Darwin.close(descriptor)
            throw AquaAutomationError.invalidSocketPath
        }

        address.sun_family = sa_family_t(AF_UNIX)
        address.sun_len = UInt8(
            MemoryLayout<sa_family_t>.size + pathBytes.count
        )
        _ = withUnsafeMutablePointer(to: &address.sun_path) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: capacity) {
                destination in
                socketPath.withCString { source in
                    strlcpy(destination, source, capacity)
                }
            }
        }

        let addressLength = socklen_t(address.sun_len)
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(descriptor, $0, addressLength)
            }
        }
        guard result == 0 else {
            let message = lastError()
            Darwin.close(descriptor)
            throw AquaAutomationError.connectFailed(message)
        }
        return descriptor
    }

    private func writeAll(_ data: Data, to descriptor: Int32) throws {
        try data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            var sent = 0
            while sent < data.count {
                let result = Darwin.write(
                    descriptor,
                    baseAddress.advanced(by: sent),
                    data.count - sent
                )
                guard result > 0 else {
                    throw AquaAutomationError.writeFailed(lastError())
                }
                sent += result
            }
        }
    }

    private func readLine(from descriptor: Int32) throws -> Data {
        let maximumResponseBytes = 1_048_576
        var response = Data()
        var byte: UInt8 = 0
        while true {
            let count = Darwin.read(descriptor, &byte, 1)
            if count == 0 {
                guard !response.isEmpty else {
                    throw AquaAutomationError.emptyResponse
                }
                return response
            }
            guard count > 0 else {
                throw AquaAutomationError.readFailed(lastError())
            }
            if byte == 0x0A { return response }
            response.append(byte)
            guard response.count <= maximumResponseBytes else {
                throw AquaAutomationError.invalidResponse
            }
        }
    }

    private func configure(descriptor: Int32) throws {
        var noSigPipe: Int32 = 1
        let noSigPipeResult = withUnsafePointer(to: &noSigPipe) {
            setsockopt(
                descriptor,
                SOL_SOCKET,
                SO_NOSIGPIPE,
                $0,
                socklen_t(MemoryLayout<Int32>.size)
            )
        }
        guard noSigPipeResult == 0 else {
            throw AquaAutomationError.connectFailed(lastError())
        }

        var timeout = timeval(tv_sec: 0, tv_usec: 250_000)
        let timeoutSize = socklen_t(MemoryLayout<timeval>.size)
        let receiveResult = withUnsafePointer(to: &timeout) {
            setsockopt(descriptor, SOL_SOCKET, SO_RCVTIMEO, $0, timeoutSize)
        }
        let sendResult = withUnsafePointer(to: &timeout) {
            setsockopt(descriptor, SOL_SOCKET, SO_SNDTIMEO, $0, timeoutSize)
        }
        guard receiveResult == 0, sendResult == 0 else {
            throw AquaAutomationError.connectFailed(lastError())
        }
    }

    private func validateSocketIfPresent() throws {
        var metadata = stat()
        guard lstat(socketPath, &metadata) == 0 else { return }
        let fileType = metadata.st_mode & mode_t(S_IFMT)
        guard fileType == mode_t(S_IFSOCK), metadata.st_uid == geteuid() else {
            throw AquaAutomationError.connectFailed(
                "The automation socket is not a user-owned Unix socket."
            )
        }
    }

    private static func makeDefaultSocketPath() -> String {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("Aquarium", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: directory.path
        )
        return directory.appendingPathComponent("aqua.sock").path
    }

    private func lastError() -> String {
        String(cString: strerror(errno))
    }
}
