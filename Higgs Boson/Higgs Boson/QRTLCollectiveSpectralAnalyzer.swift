import Foundation
import simd

final class QRTLCollectiveSpectralAnalyzer {
    private(set) var samples: [Double] = []
    private(set) var result: QRTLSpectralResult?
    let maximumSamples: Int

    init(maximumSamples: Int = 4096) {
        self.maximumSamples = maximumSamples
        samples.reserveCapacity(maximumSamples)
    }

    func reset() {
        samples.removeAll(keepingCapacity: true)
        result = nil
    }

    func append(_ value: Double) {
        guard value.isFinite else { return }
        samples.append(value)
        if samples.count > maximumSamples {
            samples.removeFirst(samples.count - maximumSamples)
        }
    }

    @discardableResult
    func analyze(sampleInterval: Double) -> QRTLSpectralResult? {
        guard samples.count >= 32, sampleInterval > 0, sampleInterval.isFinite else { return nil }
        let n = samples.count
        let mean = samples.reduce(0, +) / Double(n)
        let windowed = samples.enumerated().map { i, value in
            let w = 0.5 * (1.0 - cos(2.0 * Double.pi * Double(i) / Double(n - 1)))
            return (value - mean) * w
        }
        var bestIndex = 0
        var bestAmplitude = 0.0
        for k in 1..<(n / 2) {
            var real = 0.0
            var imaginary = 0.0
            for j in 0..<n {
                let angle = 2.0 * Double.pi * Double(k * j) / Double(n)
                real += windowed[j] * cos(angle)
                imaginary -= windowed[j] * sin(angle)
            }
            let amplitude = 2.0 * sqrt(real * real + imaginary * imaginary) / Double(n)
            if amplitude > bestAmplitude {
                bestAmplitude = amplitude
                bestIndex = k
            }
        }
        guard bestIndex > 0, bestAmplitude > 1.0e-15 else { return nil }
        let samplingFrequency = 1.0 / sampleInterval
        let frequency = Double(bestIndex) * samplingFrequency / Double(n)
        let omega = 2.0 * Double.pi * frequency
        let wavelength = QRTLConstants.speedOfLight / max(frequency, 1e-300)
        let value = QRTLSpectralResult(
            peakIndex: bestIndex,
            frequencyHz: frequency,
            angularFrequency: omega,
            wavelengthMeters: wavelength,
            peakAmplitude: bestAmplitude,
            sampleCount: n,
            sampleInterval: sampleInterval,
            samplingFrequencyHz: samplingFrequency,
            nyquistFrequencyHz: samplingFrequency * 0.5
        )
        result = value
        return value
    }
}

extension QRTLCollectiveSpectralAnalyzer {
    static func modeProjection(displacement: SIMD3<Float>, velocity: SIMD3<Float>, axis: SIMD3<Float>, omega: Double) -> (Double, Double) {
        let a = simd_normalize(axis)
        let dx = Double(displacement.x) * Double(a.x) + Double(displacement.y) * Double(a.y) + Double(displacement.z) * Double(a.z)
        let vx = Double(velocity.x) * Double(a.x) + Double(velocity.y) * Double(a.y) + Double(velocity.z) * Double(a.z)
        let phi = atan2(-vx, max(omega, 1e-300) * dx)
        return (dx, phi)
    }

    static func singleModeEnergy(x: Double, v: Double, mass: Double, k: Double) -> Double {
        let ke = 0.5 * mass * v * v
        let pe = 0.5 * k * x * x
        let e = ke + pe
        return e.isFinite ? e : 0.0
    }

    static func collectiveSample(displacement: SIMD3<Float>, velocity: SIMD3<Float>, axis: SIMD3<Float>, weight: Double) -> (disp: Double, vel: Double) {
        let a = simd_normalize(axis)
        let dx = Double(displacement.x) * Double(a.x) + Double(displacement.y) * Double(a.y) + Double(displacement.z) * Double(a.z)
        let vx = Double(velocity.x) * Double(a.x) + Double(velocity.y) * Double(a.y) + Double(velocity.z) * Double(a.z)
        return (dx * weight, vx * weight)
    }
}
