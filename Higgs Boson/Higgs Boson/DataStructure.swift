//
//  File.swift
//  Higgs Boson
//
//  Created by David Nishimoto on 9/21/26.
//

import Foundation
enum ShellPhase {
    case inactive
    case forming
    case stored
    case released
    case compressed
    case releasing
}

var shellPhase: ShellPhase = .inactive

struct EjectedUpQuark {
    var position: SIMD3<Float>
    var velocity: SIMD3<Float>
    var momentum: SIMD3<Float>
    var energyJ: Double
    var active: Bool
}

struct CollisionQuark {
    enum Flavor { case up, down }
    let flavor: Flavor
    let protonID: Int
    var position: SIMD3<Double>
    var velocity: SIMD3<Double>
    var originalPosition: SIMD3<Double>
    var compression: Double = 0.0
    var energyJ: Double = 0.0
}

struct QRTLCell {
    let index: Int
    let gridX: Int
    let gridY: Int
    let gridZ: Int
    let position: SIMD3<Float>

    var displacement = SIMD3<Float>(0, 0, 0)
    var velocity = SIMD3<Float>(0, 0, 0)
    var twist: Double = 0
    var phase: Double = 0
    var amplitude: Double = 0
    var localEnergy: Double = 0
    var localStrain: Double = 0
    var couplingState: Double = 0

    var modeCoordinate: Double = 0
    var modeVelocity: Double = 0
    var modeAcceleration: Double = 0
    var modeDirection = SIMD3<Float>(0, 0, 0)

    var previousPhase: Double = 0
    var unwrappedPhase: Double = 0
    var neighbors: [Int] = []

    // Borlagrino flow (vector in lattice units) and emergent charge
    var borlagrinoFlow = SIMD3<Float>(0, 0, 0)
    var charge: Double = 0
}

struct QRTLEnergyState {
    var equilibriumShellEnergy: Double = QRTLConstants.collisionKineticEnergyJ
    var shellEnergy: Double = QRTLConstants.collisionKineticEnergyJ
    var kineticEnergy: Double = 0
    var deformation: Double = 0
    var shellInstability: Double = 0
    var isUnstable: Bool = false
}

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


import Foundation

/// QRTLConstants holds fundamental physical and simulation parameters.
/// Correct mechanical energy injection and spectralSampleInterval synchrony are crucial
/// for proper simulation and FFT analysis.
struct EnergyState {

    var shellEnergy: Double = 0.0
    var equilibriumShellEnergy: Double = 0.0

    var shellCompression: Double = 0.0
    var deformation: Double = 0.0
    var shellInstability: Double = 0.0

    var isUnstable: Bool = false
}
enum QRTLConstants {

    static let collisionEnergyGeV: Double = 4_000.0

    /// Collision energy in joules.
    static let collisionKineticEnergyJ: Double =
        collisionEnergyGeV * joulesPerGeV

    /// Same collision budget expressed explicitly for diagnostics.
    static let protonProtonCollisionEnergyGeV: Double =
        collisionEnergyGeV

    static let protonProtonCollisionEnergyJ: Double =
        collisionEnergyGeV * joulesPerGeV
    static let maximumSimulationVelocityMPerS =
        299_792_458.0
    static let shellLatticeTransferFraction = 1.0
    static let shellLifetimeSeconds = 1.0e-22
    static let joulesPerGeV = 1.602176634e-10

     static let targetHiggsMassGeV = 125.0

     static let higgsReferenceEnergyJ =
         targetHiggsMassGeV * joulesPerGeV

     // ------------------------------------------------------------
     // PHYSICAL LATTICE TIMESTEP
     // ------------------------------------------------------------

     static let timeStep = 0.002

     // ------------------------------------------------------------
     // FFT SAMPLING
     //
     // This is NOT automatically the same thing as the SceneKit
     // frame interval.
     // ------------------------------------------------------------

     static let spectralSampleCount = 4096

    static let spectralSampleInterval = timeStep  // Must match simulation physics timestep
     static let spectralSampleRate =
         1.0 / spectralSampleInterval

     static let spectralNyquistFrequency =
         0.5 * spectralSampleRate
    static let activeEnergyThreshold = 1e-35
    static let targetLatticeFraction = 0.5


    // Numerical cell-activity cutoff.
    // This is NOT the Higgs energy.
    static let activeEnergyThresholdJ = 1.0e-35

    static let physicsStepsPerFrame = 4

    static let collisionKineticFractionToPotential = 0.50
    
    static let helium2MinimumShellEnergyGeV: Double = 1.0e-6
    static let helium2MaximumSeparation: Double = 2.0
    static let helium2MinimumPersistenceSamples: Int = 5
    static let helium2DissolutionEnergyFraction: Double = 0.50
    static let protonVelocityMPerS: Double = 1.0e8
    static let protonMassKg: Double = 1.67262192369e-27
    static let cellSpacing: Double = 1.0
    static let collisionRadius: Double = 5.0
    static let minimumCoherence: Double = 0.70
    static let minimumResonanceDuration: Double = 1.0
    static let stableEnergyTolerance = 0.001
    static let higgsEnergyTolerance = 0.05
  static let sampleCount = 1000
    static let phaseStiffness: Double = 0.03
    static let twistStiffness: Double = 0.08
    static let upQuarkMassKg = 3.85e-30
    static let pumpRadius = 3.0
    static let planckConstant = 6.62607015e-34
    static let speedOfLight = 299_792_458.0
    static let joulePerGeV = 1.602176634e-10

    static let latticeSize = 17
    static let coupling = 0.16
    static let twistCoupling = 0.08
    static let phaseCoupling = 0.12
    static let strainCoupling = 0.06
    static let restoringForce = 0.20
    static let damping = 0.002
    static let twistRestoring = 0.08
    static let phaseRestoring = 0.03

    // Softened mechanical scale so lattice state stays finite in sim units
    static let effectiveMassKg = 1.0e-24
    static let effectiveStiffnessNPerM = 3.606e28
    static let latticeCellSpacingMeters = 1.0e-15
     static let dampingRatePerSecond = 2.0e23
    static let shellRelaxationRatePerSecond = 1.0e24

    // Clamp lattice oscillator coordinates (prevents inf energy)
    static let maxLatticeDisplacement = 50.0

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

    static let initialProtonX = 6.0
    static let protonSpeed = 4.0
    static let collisionDistance = 0.55
    static let excitationRadius = 3.0
    static let sceneScale: Float = 0.75

    // Borlagrino / charge (dimensionless lattice flow; does not create energy)
    static let borlagrinoCoupling = 0.12
    static let borlagrinoDamping = 0.05
    static let chargeFromCirculation = 0.25
    static let twistAttractStrength = 0.10
    static let twistRepelStrength = 0.12
    

}






