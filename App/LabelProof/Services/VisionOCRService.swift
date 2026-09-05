import Foundation
import LabelProofCore

#if canImport(Vision) && canImport(UIKit)
import Vision
import UIKit

/// `OCRServicing` implementation backed by Apple Vision's
/// `VNRecognizeTextRequest`. Entirely on-device — no network calls.
/// Structurally correct but NOT executed/verified in this cloud sandbox
/// (no Xcode/Simulator/device available); see docs/LOCAL_QA_HANDOFF.md.
struct VisionOCRService: OCRServicing {
    func recognizeText(imageData: Data) async throws -> [String] {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw ScanServiceError.underlying("Could not decode image data")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: ScanServiceError.underlying(error.localizedDescription))
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            // Packaging text is short/dense; language correction can be a
            // false-positive source, but accuracy over speed is preferred
            // for a verification tool.

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ScanServiceError.underlying(error.localizedDescription))
            }
        }
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
#endif
