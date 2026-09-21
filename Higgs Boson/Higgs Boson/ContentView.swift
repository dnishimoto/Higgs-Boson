import SwiftUI

import SceneKit

import simd

import Combine

// ============================================================

// MARK: - CONTENT VIEW

// ============================================================

struct ContentView: View {

    @StateObject private var simulation = QRTLSimulation()

    var body: some View {

        ZStack(alignment: .top) {

            Color.black

                .ignoresSafeArea()

            VStack(spacing: 0) {

                SceneView(

                    scene: simulation.scene,

                    pointOfView: simulation.cameraNode,

                    options: [

                        .allowsCameraControl,

                        .autoenablesDefaultLighting

                    ]

                )

                .frame(maxWidth: .infinity)

                .frame(height: 470)

                ScrollView {

                    VStack(spacing: 10) {

                        collisionCard

                        qrtlShellCard

                        latticeCard

                        energyCard

                        higgsCard

                        Button("Reset Simulation") {

                            simulation.reset()

                        }

                        .buttonStyle(.borderedProminent)

                        .padding(.vertical, 8)

                    }

                    .padding()

                }

                .background(Color.black)

            }

        }

        .onAppear {

            simulation.start()

        }

        .onDisappear {

            simulation.stop()

        }

    }

    // ========================================================

    // MARK: - COLLISION CARD

    // ========================================================

    private var collisionCard: some View {

        monitorCard(

            title: "COLLISION",

            symbol: "bolt.fill"

        ) {

            HStack {

                valueRow(

                    label: "Proton A",

                    value: simulation.protonAState

                )

                Spacer()

                valueRow(

                    label: "Distance",

                    value: String(

                        format: "%.3f",

                        simulation.protonDistance

                    )

                )

                Spacer()

                valueRow(

                    label: "Proton B",

                    value: simulation.protonBState

                )

            }

            Divider()

                .background(Color.gray)

            statusRow(

                label: "Collision",

                status: simulation.collisionOccurred

                    ? "OCCURRED"

                    : "APPROACHING",

                active: simulation.collisionOccurred

            )

        }

    }

    // ========================================================

    // MARK: - QRTL SHELL CARD

    // ========================================================

    private var qrtlShellCard: some View {

        monitorCard(

            title: "QRTL SHELL",

            symbol: "circle.hexagongrid.fill"

        ) {

            metricRow(

                label: "Shell Energy",

                value: "\(format(simulation.energyState.shellEnergy))"

            )

            metricRow(

                label: "Equilibrium Energy",

                value: "\(format(simulation.energyState.equilibriumShellEnergy))"

            )

            metricRow(

                label: "Instability",

                value: "\(formatPercent(simulation.energyState.shellInstability))"

            )

            metricRow(

                label: "Deformation",

                value: "\(format(simulation.energyState.deformation))"

            )

            Divider()

                .background(Color.gray)

            statusRow(

                label: "Shell State",

                status: simulation.energyState.isUnstable

                    ? "UNSTABLE"

                    : "STABLE",

                active: simulation.energyState.isUnstable

            )

        }

    }

    // ========================================================

    // MARK: - LATTICE CARD

    // ========================================================

    private var latticeCard: some View {

        monitorCard(

            title: "QUARK-LATTICE CA",

            symbol: "square.grid.3x3.fill"

        ) {

            metricRow(

                label: "Active Cells",

                value: "\(simulation.activeCellCount)"

            )

            metricRow(

                label: "Collective Coherence",

                value: formatPercent(simulation.collectiveCoherence)

            )

            metricRow(

                label: "Average Strain",

                value: format(simulation.averageStrain)

            )

            metricRow(

                label: "Average Twist",

                value: format(simulation.averageTwist)

            )

            metricRow(

                label: "Collective Amplitude",

                value: format(simulation.collectiveAmplitude)

            )

            Divider()

                .background(Color.gray)

            statusRow(

                label: "Lattice State",

                status: simulation.latticeExcited

                    ? "EXCITED"

                    : "EQUILIBRIUM",

                active: simulation.latticeExcited

            )

        }

    }

    // ========================================================

    // MARK: - ENERGY CARD

    // ========================================================

    private var energyCard: some View {

        monitorCard(

            title: "ENERGY",

            symbol: "waveform.path.ecg"

        ) {

            metricRow(

                label: "Formation Threshold",

                value: "\(format(simulation.formationThresholdEnergy))"

            )

            metricRow(

                label: "Lattice Energy",

                value: "\(format(simulation.latticeEnergy))"

            )

            metricRow(

                label: "Resonant Mode Energy",

                value: "\(format(simulation.resonantModeEnergy))"

            )

            metricRow(

                label: "Energy Concentration",

                value: formatPercent(simulation.energyConcentration)

            )

        }

    }

    // ========================================================

    // MARK: - HIGGS-LIKE MODE CARD

    // ========================================================

    private var higgsCard: some View {

        monitorCard(

            title: "HIGGS-LIKE MODE",

            symbol: "wave.3.right"

        ) {

            metricRow(

                label: "Resonant Mass",

                value: "\(format(simulation.resonantMassGeV)) GeV"

            )

            metricRow(

                label: "Formation Threshold",

                value: "\(format(simulation.formationThresholdEnergy))"

            )

            metricRow(

                label: "Mode Energy",

                value: "\(format(simulation.resonantModeEnergy))"

            )

            metricRow(

                label: "Frequency",

                value: "\(formatScientific(simulation.resonantFrequencyHz)) Hz"

            )

            metricRow(

                label: "Angular Frequency",

                value: "\(formatScientific(simulation.resonantAngularFrequency)) rad/s"

            )

            metricRow(

                label: "Wavelength",

                value: "\(formatScientific(simulation.resonantWavelengthMeters)) m"

            )

            metricRow(

                label: "FFT Samples",

                value: "\(simulation.spectralSampleCount) / \(QRTLConstants.spectralSampleCount)"

            )

            metricRow(

                label: "Nyquist Limit",

                value: "\(formatScientific(simulation.spectralNyquistHz)) Hz"

            )

            metricRow(

                label: "Amplitude",

                value: format(simulation.higgsMode.amplitude)

            )

            metricRow(

                label: "Coherence",

                value: formatPercent(simulation.higgsMode.coherence)

            )

            Divider()

                .background(Color.gray)

            metricRow(

                label: "Target",

                value: "125.000 GeV"

            )

            metricRow(

                label: "Target Frequency",

                value: "\(formatScientific(simulation.targetFrequencyHz)) Hz"

            )

            metricRow(

                label: "Distance",

                value: "\(format(simulation.massDistanceFromTarget)) GeV"

            )

            Divider()

                .background(Color.gray)

            statusRow(

                label: "Mode",

                status: simulation.higgsModeStatus,

                active: simulation.higgsMode.active

            )

        }

    }

    // ========================================================

    // MARK: - CARD HELPERS

    // ========================================================

    private func monitorCard<Content: View>(

        title: String,

        symbol: String,

        @ViewBuilder content: () -> Content

    ) -> some View {

        VStack(

            alignment: .leading,

            spacing: 10

        ) {

            HStack {

                Image(systemName: symbol)

                Text(title)

                    .font(.headline)

                Spacer()

            }

            .foregroundColor(.white)

            content()

        }

        .padding()

        .background(

            RoundedRectangle(cornerRadius: 12)

                .fill(Color.white.opacity(0.08))

        )

        .overlay(

            RoundedRectangle(cornerRadius: 12)

                .stroke(

                    Color.white.opacity(0.15),

                    lineWidth: 1

                )

        )

    }

    private func metricRow(

        label: String,

        value: String

    ) -> some View {

        HStack {

            Text(label)

                .foregroundColor(.gray)

            Spacer()

            Text(value)

                .foregroundColor(.white)

                .monospacedDigit()

        }

        .font(.system(size: 14))

    }

    private func valueRow(

        label: String,

        value: String

    ) -> some View {

        VStack(spacing: 3) {

            Text(label)

                .font(.caption)

                .foregroundColor(.gray)

            Text(value)

                .font(.system(size: 13))

                .foregroundColor(.white)

        }

    }

    private func statusRow(

        label: String,

        status: String,

        active: Bool

    ) -> some View {

        HStack {

            Text(label)

                .foregroundColor(.gray)

            Spacer()

            Text(status)

                .fontWeight(.semibold)

                .foregroundColor(

                    active ? .green : .orange

                )

        }

    }

    private func format(

        _ value: Double

    ) -> String {

        String(

            format: "%.6f",

            value

        )

    }

    private func formatPercent(

        _ value: Double

    ) -> String {

        String(

            format: "%.1f%%",

            value * 100.0

        )

    }

    private func formatScientific(

        _ value: Double

    ) -> String {

        guard value.isFinite,

              value > 0

        else {

            return "0"

        }

        return String(

            format: "%.3e",

            value

        )

    }

}

// ============================================================

// MARK: - QRTL CONSTANTS

// ============================================================

enum QRTLConstants {

    static let targetHiggsMassGeV = 125.0

    static let planckConstant =

        6.62607015e-34

    static let speedOfLight = 299_792_458.0

    static let spectralSampleCount = 4096

    static let joulePerGeV =

        1.602176634e-10

    // --------------------------------------------------------

    // Lattice

    // --------------------------------------------------------

    static let latticeSize = 17

    static let coupling = 0.16

    static let twistCoupling = 0.08

    static let phaseCoupling = 0.12

    static let strainCoupling = 0.06

    static let restoringForce = 0.20

    static let damping = 0.008

    static let twistRestoring = 0.08

    static let phaseRestoring = 0.03

    // --------------------------------------------------------

    // Collision

    // --------------------------------------------------------

    static let initialProtonX = 6.0

    static let protonSpeed = 4.0

    static let collisionDistance = 0.55

    // --------------------------------------------------------

    // Simulation

    // --------------------------------------------------------

    static let timeStep = 0.002

    static let physicsStepsPerFrame = 4

    // --------------------------------------------------------

    // Pump / collision energy

    // --------------------------------------------------------

    static let collisionEnergy = 1.0

    static let excitationRadius = 3.0

    // --------------------------------------------------------

    // Visual

    // --------------------------------------------------------

    static let sceneScale: Float = 0.75

}

// ============================================================

// MARK: - QRTL CELL

// ============================================================

struct QRTLCell {

    let index: Int

    let gridX: Int

    let gridY: Int

    let gridZ: Int

    let position: SIMD3<Float>

    // --------------------------------------------------------

    // QRTL lattice state

    // --------------------------------------------------------

    var displacement = SIMD3<Float>(0, 0, 0)

    var velocity = SIMD3<Float>(0, 0, 0)

    var twist: Double = 0

    var phase: Double = 0

    var amplitude: Double = 0

    var localEnergy: Double = 0

    var localStrain: Double = 0

    var couplingState: Double = 0

    // --------------------------------------------------------

    // Genuine oscillator state

    // --------------------------------------------------------

    var modeCoordinate: Double = 0

    var modeVelocity: Double = 0

    var modeAcceleration: Double = 0

    // Phase history is now generated from the oscillator.

    var previousPhase: Double = 0

    var unwrappedPhase: Double = 0

    // --------------------------------------------------------

    // Neighbor indices

    // --------------------------------------------------------

    var neighbors: [Int] = []

}

// ============================================================

// MARK: - ENERGY STATE

// ============================================================

struct QRTLEnergyState {

    var equilibriumShellEnergy: Double = 1.0

    var shellEnergy: Double = 1.0

    var kineticEnergy: Double = 0

    var deformation: Double = 0

    var shellInstability: Double = 0

    var isUnstable: Bool = false

}

// ============================================================

// MARK: - HIGGS-LIKE MODE

// ============================================================

struct HiggsLikeMode {

    var active: Bool = false

    var age: Double = 0

    var energy: Double = 0

    var frequencyHz: Double = 0

    var massGeV: Double = 0

    var amplitude: Double = 0

    var phase: Double = 0

    var coherence: Double = 0

    var shellEnergy: Double = 0

    var shellInstability: Double = 0

    var decayProgress: Double = 0

}

// ============================================================

// ============================================================
// MARK: - COLLECTIVE SPECTRAL ANALYSIS
// ============================================================

struct QRTLSpectralResult {
    let peakIndex: Int
    let frequencyHz: Double
    let angularFrequency: Double
    let wavelengthMeters: Double
    let peakAmplitude: Double
    let sampleCount: Int
    let sampleInterval: Double
    let samplingFrequencyHz: Double
    let nyquistFrequencyHz: Double
}

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
        let wavelength = QRTLConstants.speedOfLight / frequency
        let value = QRTLSpectralResult(peakIndex: bestIndex, frequencyHz: frequency, angularFrequency: omega, wavelengthMeters: wavelength, peakAmplitude: bestAmplitude, sampleCount: n, sampleInterval: sampleInterval, samplingFrequencyHz: samplingFrequency, nyquistFrequencyHz: samplingFrequency * 0.5)
        result = value
        return value
    }
}

