import Alamofire
import Combine
import Foundation

class DownloadService {
    private let queue: DispatchQueue
    private var downloads = [String: Double]()

    @Published private(set) var state: State = .idle

    init(queueLabel: String = "io.SynchronizedDownloader") {
        queue = DispatchQueue(label: queueLabel, qos: .background)
    }

    private func request(source: URLConvertible, destination: @escaping DownloadRequest.Destination, progress: ((Double) -> Void)? = nil, completion: ((Bool) -> Void)? = nil) {
        guard let key = try? source.asURL().path else {
            return
        }

        let alreadyDownloading = queue.sync {
            downloads.contains(where: { existKey, _ in key == existKey })
        }

        guard !alreadyDownloading else {
            state = .success
            return
        }

        handle(progress: 0, key: key)
        AF.download(source, to: destination)
            .downloadProgress(queue: DispatchQueue.global(qos: .background)) { [weak self] progressValue in
                self?.handle(progress: progressValue.fractionCompleted, key: key)
                progress?(progressValue.fractionCompleted)
            }
            .responseData(queue: DispatchQueue.global(qos: .background)) { [weak self] response in
                self?.handle(response: response, key: key)
                switch response.result { // extend errors/data to completion if needed
                case .success: completion?(true)
                case .failure: completion?(false)
                }
            }
    }

    private func handle(progress: Double, key: String) {
        queue.async {
            self.downloads[key] = progress
            self.syncState()
        }
    }

    private func handle(response _: AFDownloadResponse<Data>, key: String) {
        queue.async {
            self.downloads[key] = nil
            self.syncState()
        }
    }

    private func syncState() {
        var lastProgress: Double = 0

        if case let .inProgress(value) = state {
            lastProgress = value
        }

        guard downloads.count != 0 else {
            state = .success
            return
        }

        let minimalProgress = downloads.min(by: { a, b in a.value < b.value })?.value ?? lastProgress
        state = .inProgress(value: max(minimalProgress, lastProgress))
    }
}

extension DownloadService {
    public func download(source: URLConvertible, destination: URL, progress: ((Double) -> Void)? = nil, completion: ((Bool) -> Void)? = nil) {
        let destination: DownloadRequest.Destination = { _, _ in
            (destination, [.removePreviousFile, .createIntermediateDirectories])
        }

        request(source: source, destination: destination, progress: progress, completion: completion)
    }
}

extension DownloadService {
    public static func existing(url: URL) -> Bool {
        (try? FileManager.default.attributesOfItem(atPath: url.path)) != nil
    }

    public enum State: Equatable {
        case idle
        case inProgress(value: Double)
        case success

        public static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.success, .success): return true
            case let (.inProgress(lhsValue), .inProgress(rhsValue)): return lhsValue == rhsValue
            default: return false
            }
        }
    }
}
