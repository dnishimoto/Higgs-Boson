//
//  File.swift
//  Higgs Boson
//
//  Created by David Nishimoto on 9/21/26.
//

import Foundation
import SwiftUI

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
