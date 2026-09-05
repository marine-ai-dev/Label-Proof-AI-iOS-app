import Foundation
import LabelProofCore

#if canImport(Vision) && canImport(UIKit)
import Vision
import UIKit

/// `BarcodeServicing` implementation backed by Apple Vision's
/// `VNDetectBarcodesRequest`. Entirely on-device. Structurally correct but
/// NOT executed/verified in this cloud sandbox; see docs/LOCAL_QA_HANDOFF.md.
struct VisionBarcodeService: BarcodeServicing {
    func recognizeBarcodes(imageData: Data) async throws -> [BarcodeObservation] {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw ScanServiceError.underlying("Could not decode image data")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error {
                    continuation.resume(throwing: ScanServiceError.underlying(error.localizedDescription))
                    return
                }
                let observations = request.results as? [VNBarcodeObservation] ?? []
                let barcodes = observations.compactMap { observation -> BarcodeObservation? in
                    guard let payload = observation.payloadStringValue else { return nil }
                    return BarcodeObservation(payload: payload, symbology: observation.symbology.rawValue)
                }
                // Deduplication happens again inside ExtractedLabelData's
                // initializer, but we also dedupe here to keep this service's
                // own output self-consistent.
                continuation.resume(returning: ExtractedLabelData.deduplicate(barcodes))
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ScanServiceError.underlying(error.localizedDescription))
            }
        }
    }
}
#endif
