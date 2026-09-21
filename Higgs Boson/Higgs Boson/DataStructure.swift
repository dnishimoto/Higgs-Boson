//
//  File.swift
//  Higgs Boson
//
//  Created by David Nishimoto on 9/21/26.
//

import Foundation
enum QRTLConstants {

    static let targetHiggsMassGeV = 125.0
    static let planckConstant = 6.62607015e-34
    static let speedOfLight = 299_792_458.0
    static let spectralSampleCount = 4096
    static let joulePerGeV = 1.602176634e-10

    static let latticeSize = 17
    static let coupling = 0.16
    static let twistCoupling = 0.08
    static let phaseCoupling = 0.12
    static let strainCoupling = 0.06
    static let restoringForce = 0.20
    static let damping = 0.008
    static let twistRestoring = 0.08
    static let phaseRestoring = 0.03

    // Physical QRTL mechanical scale. Cell displacement and velocity
    // remain in lattice units; energy is calculated after conversion
    // to meters and seconds.
    static let effectiveMassKg = 1.0e-24
    static let effectiveStiffnessNPerM = 1.0e28
    static let latticeCellSpacingMeters = 1.0e-15
    static let collisionKineticFractionToPotential = 0.50
    static let dampingRatePerSecond = 2.0e23
    static let shellRelaxationRatePerSecond = 1.0e24

    // LHC Run-3 beam values used for the incoming collision budget.
    static let protonRestEnergyGeV = 0.93827208816
    static let lhcProtonBeamEnergyTeV = 6.8
    static let lhcProtonBeamEnergyGeV = lhcProtonBeamEnergyTeV * 1_000.0
    static let lhcLorentzFactor = lhcProtonBeamEnergyGeV / protonRestEnergyGeV
    static let lhcProtonSpeed: Double = {
        let gamma = lhcLorentzFactor
        guard gamma > 1.0 else { return 0.0 }
        return speedOfLight * sqrt(1.0 - 1.0 / (gamma * gamma))
    }()
    static let singleProtonKineticEnergyGeV =
        (lhcLorentzFactor - 1.0) * protonRestEnergyGeV
    static let twoProtonKineticEnergyGeV =
        2.0 * singleProtonKineticEnergyGeV
    static let protonProtonCollisionEnergyGeV =
        2.0 * lhcProtonBeamEnergyGeV
    static let collisionKineticEnergyJ =
        twoProtonKineticEnergyGeV * joulePerGeV
    static let protonProtonCollisionEnergyJ =
        protonProtonCollisionEnergyGeV * joulePerGeV

    static let initialProtonX = 6.0
    static let protonSpeed = 4.0
    static let collisionDistance = 0.55
    static let timeStep = 1.0e-27
    static let physicsStepsPerFrame = 4
    static let excitationRadius = 3.0
    static let activeEnergyThresholdJ = 1.0e-18
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
    var modeDirection = SIMD3<Float>(0, 0, 0)

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

    var equilibriumShellEnergy: Double = QRTLConstants.targetHiggsMassGeV * QRTLConstants.joulePerGeV

    var shellEnergy: Double = QRTLConstants.targetHiggsMassGeV * QRTLConstants.joulePerGeV

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
