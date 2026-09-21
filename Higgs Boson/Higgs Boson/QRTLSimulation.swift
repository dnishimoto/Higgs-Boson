//
//  File.swift
//  Higgs Boson
//
//  Created by David Nishimoto on 9/21/26.
//

import SwiftUI

import SceneKit
import SwiftUI
import simd

import Combine

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


final class QRTLSimulation: ObservableObject {

    // ========================================================

    // MARK: Published State

    // ========================================================

    @Published var energyState =

        QRTLEnergyState()

    @Published var higgsMode =

        HiggsLikeMode()

    @Published var collisionOccurred = false

    @Published var latticeExcited = false

    @Published var collectiveCoherence = 0.0

    @Published var collectiveAmplitude = 0.0

    @Published var averageStrain = 0.0

    @Published var averageTwist = 0.0

    @Published var latticeEnergy = 0.0

    @Published var resonantModeEnergy = 0.0

    @Published var resonantFrequencyHz = 0.0
    @Published var resonantAngularFrequency = 0.0
    @Published var resonantWavelengthMeters = 0.0
    @Published var spectralPeakAmplitude = 0.0
    @Published var spectralSampleCount = 0
    @Published var spectralNyquistHz = 0.0
    @Published var collisionKineticEnergyJ = 0.0
    @Published var collisionKineticEnergyGeV = 0.0
    @Published var collisionKineticEnergyTeV = 0.0
    @Published var depositedEnergyJ = 0.0
    @Published var depositedEnergyGeV = 0.0
    @Published var depositedEnergyTeV = 0.0
    @Published var currentLatticeEnergyJ = 0.0
    @Published var currentLatticeEnergyGeV = 0.0
    @Published var currentLatticeEnergyTeV = 0.0
    @Published var resonantModeEnergyJ = 0.0
    @Published var resonantModeEnergyGeV = 0.0
    @Published var resonantModeEnergyTeV = 0.0
    @Published var dissipatedEnergyJ = 0.0
    @Published var dissipatedEnergyGeV = 0.0
    @Published var dissipatedEnergyTeV = 0.0
    @Published var energyBalanceErrorJ = 0.0
    @Published var energyBalanceErrorGeV = 0.0
    @Published var initialAffectedCellCount = 0
    @Published var energyRadius = 0.0
    @Published var peakCellEnergyGeV = 0.0
    @Published var peakEnergyFraction = 0.0
    @Published var peakCollectiveAmplitude = 0.0
    @Published var propagationTime = 0.0
    @Published var resonanceDevelopment = 0.0
    @Published var dampingFraction = 0.0
    @Published var returnedToEquilibrium = false


    @Published var resonantMassGeV = 0.0

    @Published var formationThresholdEnergy = 0.0

    @Published var massDistanceFromTarget =

        QRTLConstants.targetHiggsMassGeV

    @Published var protonAState = "MOVING"

    @Published var protonBState = "MOVING"

    @Published var protonDistance =

        QRTLConstants.initialProtonX * 2.0

    // ========================================================

    // MARK: Scene

    // ========================================================

    let scene = SCNScene()

    let cameraNode = SCNNode()

    private let protonANode = SCNNode()

    private let protonBNode = SCNNode()

    private let protonAShellNode = SCNNode()

    private let protonBShellNode = SCNNode()

    private let latticeParentNode = SCNNode()

    private let higgsNode = SCNNode()

    // ========================================================

    // MARK: Simulation State

    // ========================================================

    private var cells: [QRTLCell] = []

    private var cellNodes: [SCNNode] = []

    private var running = false

    private var timer: Timer?

    private var simulationTime = 0.0

    private var protonAX =

        -QRTLConstants.initialProtonX

    private var protonBX =

        QRTLConstants.initialProtonX

    private var collisionTime = 0.0

    // ========================================================

    // MARK: Collective Oscillation Measurement

    // ========================================================

    private var previousCollectiveSignal = 0.0

    private var previousCollectiveVelocity = 0.0

    private var lastPositiveCrossingTime: Double?

    private var measuredPeriods: [Double] = []

    private var phaseReferenceEstablished = false
    private let spectralAnalyzer = QRTLCollectiveSpectralAnalyzer(maximumSamples: QRTLConstants.spectralSampleCount)
    private var spectralAnalysisComplete = false

    // ========================================================

    // MARK: Target Frequency

    // ========================================================

    var targetFrequencyHz: Double {

        let targetEnergyJoules =

            QRTLConstants.targetHiggsMassGeV *

            QRTLConstants.joulePerGeV

        return targetEnergyJoules /

            QRTLConstants.planckConstant

    }

    // ========================================================

    // MARK: Derived Values

    // ========================================================

    var activeCellCount: Int {

        cells.reduce(into: 0) { result, cell in

            if cell.localEnergy > QRTLConstants.activeEnergyThresholdJ {

                result += 1

            }

        }

    }

    var energyConcentration: Double {

        guard latticeEnergy > 0 else {

            return 0

        }

        guard resonantModeEnergy > 0 else {

            return 0

        }

        return min(

            1.0,

            resonantModeEnergy /

            latticeEnergy

        )

    }

    var higgsModeStatus: String {

        if !collisionOccurred {

            return "WAITING FOR COLLISION"

        }

        if energyState.isUnstable &&

            !higgsMode.active {

            return "SHELL INSTABILITY"

        }

        if higgsMode.active &&

            resonantFrequencyHz > 0 {

            return "RESONANT MODE FORMING"

        }

        if latticeExcited {

            return "LATTICE OSCILLATING"

        }

        return "ENERGY TRANSFER"

    }

    // ========================================================

    // MARK: Initialization

    // ========================================================

    init() {

        configureScene()

        buildLattice()

        createProtons()

        createHiggsNode()

    }

    // ========================================================

    // MARK: Scene Configuration

    // ========================================================

    private func configureScene() {

        scene.background.contents = UIColor.black

        // Lattice at origin

        latticeParentNode.position = SCNVector3(

            0,

            0,

            0

        )

        scene.rootNode.addChildNode(

            latticeParentNode

        )

        // Protons

        scene.rootNode.addChildNode(

            protonANode

        )

        scene.rootNode.addChildNode(

            protonBNode

        )

        scene.rootNode.addChildNode(

            protonAShellNode

        )

        scene.rootNode.addChildNode(

            protonBShellNode

        )

        // Higgs-like mode

        scene.rootNode.addChildNode(

            higgsNode

        )

        // Camera

        cameraNode.camera = SCNCamera()

        cameraNode.camera?.fieldOfView = 50

        cameraNode.camera?.zNear = 0.01

        cameraNode.camera?.zFar = 1000

        cameraNode.position = SCNVector3(

            0,

            0,

            45

        )

        let cameraTargetNode = SCNNode()

        cameraTargetNode.position = SCNVector3(

            0,

            0,

            0

        )

        scene.rootNode.addChildNode(

            cameraTargetNode

        )

        let lookAt =

            SCNLookAtConstraint(

                target: cameraTargetNode

            )

        lookAt.isGimbalLockEnabled = true

        cameraNode.constraints = [

            lookAt

        ]

        scene.rootNode.addChildNode(

            cameraNode

        )

        // Lighting

        let lightNode = SCNNode()

        let light = SCNLight()

        light.type = .omni

        light.intensity = 1500

        lightNode.light = light

        lightNode.position = SCNVector3(

            0,

            10,

            20

        )

        scene.rootNode.addChildNode(

            lightNode

        )

    }

    // ========================================================

    // MARK: Build Lattice

    // ========================================================

    private func buildLattice() {

        cells.removeAll()

        cellNodes.removeAll()

        let n =

            QRTLConstants.latticeSize

        let center =

            Float(n - 1) / 2.0

        var index = 0

        for z in 0..<n {

            for y in 0..<n {

                for x in 0..<n {

                    let position =

                        SIMD3<Float>(

                            Float(x) - center,

                            Float(y) - center,

                            Float(z) - center

                        )

                    let cell =

                        QRTLCell(

                            index: index,

                            gridX: x,

                            gridY: y,

                            gridZ: z,

                            position: position

                        )

                    cells.append(cell)

                    let node =

                        makeLatticeNode()

                    node.position =

                        SCNVector3(

                            position.x *

                                QRTLConstants.sceneScale,

                            position.y *

                                QRTLConstants.sceneScale,

                            position.z *

                                QRTLConstants.sceneScale

                        )

                    latticeParentNode.addChildNode(

                        node

                    )

                    cellNodes.append(node)

                    index += 1

                }

            }

        }

        buildNeighborLookup()

    }

    // ========================================================

    // MARK: Neighbor Lookup

    // ========================================================

    private func buildNeighborLookup() {

        let n =

            QRTLConstants.latticeSize

        for index in cells.indices {

            let x = cells[index].gridX

            let y = cells[index].gridY

            let z = cells[index].gridZ

            var neighbors: [Int] = []

            let offsets = [

                (-1, 0, 0),

                (1, 0, 0),

                (0, -1, 0),

                (0, 1, 0),

                (0, 0, -1),

                (0, 0, 1)

            ]

            for offset in offsets {

                let nx = x + offset.0

                let ny = y + offset.1

                let nz = z + offset.2

                guard nx >= 0,

                      nx < n,

                      ny >= 0,

                      ny < n,

                      nz >= 0,

                      nz < n

                else {

                    continue

                }

                let neighborIndex =

                    nx +

                    ny * n +

                    nz * n * n

                neighbors.append(

                    neighborIndex

                )

            }

            cells[index].neighbors =

                neighbors

        }

    }

    // ========================================================

    // MARK: Lattice Node

    // ========================================================

    private func makeLatticeNode() -> SCNNode {

        let geometry =

            SCNSphere(

                radius: 0.055

            )

        geometry.segmentCount = 6

        let material =

            SCNMaterial()

        material.diffuse.contents =

            UIColor(

                white: 0.18,

                alpha: 0.45

            )

        geometry.materials = [

            material

        ]

        return SCNNode(

            geometry: geometry

        )

    }

    // ========================================================

    // MARK: Create Protons

    // ========================================================

    private func createProtons() {

        let protonAGeometry =

            SCNSphere(

                radius: 0.42

            )

        protonAGeometry.segmentCount = 24

        let protonAMaterial =

            SCNMaterial()

        protonAMaterial.diffuse.contents =

            UIColor.cyan

        protonAMaterial.emission.contents =

            UIColor.cyan

        protonAGeometry.materials = [

            protonAMaterial

        ]

        protonANode.geometry =

            protonAGeometry

        protonANode.position =

            SCNVector3(

                Float(protonAX),

                0,

                0

            )

        scene.rootNode.addChildNode(

            protonANode

        )

        let protonBGeometry =

            SCNSphere(

                radius: 0.42

            )

        protonBGeometry.segmentCount = 24

        let protonBMaterial =

            SCNMaterial()

        protonBMaterial.diffuse.contents =

            UIColor.red

        protonBMaterial.emission.contents =

            UIColor.red

        protonBGeometry.materials = [

            protonBMaterial

        ]

        protonBNode.geometry =

            protonBGeometry

        protonBNode.position =

            SCNVector3(

                Float(protonBX),

                0,

                0

            )

        scene.rootNode.addChildNode(

            protonBNode

        )

        // ----------------------------------------------------

        // Proton shells

        // ----------------------------------------------------

        let shellAGeometry =

            SCNSphere(

                radius: 0.58

            )

        shellAGeometry.segmentCount = 20

        let shellAMaterial =

            SCNMaterial()

        shellAMaterial.diffuse.contents =

            UIColor.cyan.withAlphaComponent(0.08)

        shellAMaterial.transparency = 0.15

        shellAGeometry.materials = [

            shellAMaterial

        ]

        protonAShellNode.geometry =

            shellAGeometry

        scene.rootNode.addChildNode(

            protonAShellNode

        )

        let shellBGeometry =

            SCNSphere(

                radius: 0.58

            )

        shellBGeometry.segmentCount = 20

        let shellBMaterial =

            SCNMaterial()

        shellBMaterial.diffuse.contents =

            UIColor.red.withAlphaComponent(0.08)

        shellBMaterial.transparency = 0.15

        shellBGeometry.materials = [

            shellBMaterial

        ]

        protonBShellNode.geometry =

            shellBGeometry

        scene.rootNode.addChildNode(

            protonBShellNode

        )

    }

    // ========================================================

    // MARK: Higgs Visual Node

    // ========================================================

    private func createHiggsNode() {

        let geometry =

            SCNSphere(

                radius: 0.65

            )

        geometry.segmentCount = 24

        let material =

            SCNMaterial()

        material.diffuse.contents =

            UIColor.purple

        material.emission.contents =

            UIColor.purple.withAlphaComponent(0.8)

        material.transparency = 0.0

        geometry.materials = [

            material

        ]

        higgsNode.geometry =

            geometry

        higgsNode.position =

            SCNVector3(

                0,

                0,

                0

            )

        higgsNode.isHidden = true

        scene.rootNode.addChildNode(

            higgsNode

        )

    }

    // ========================================================

    // MARK: Start

    // ========================================================

    func start() {

        guard !running else {

            return

        }

        running = true

        timer =

            Timer.scheduledTimer(

                withTimeInterval: 1.0 / 60.0,

                repeats: true

            ) { [weak self] _ in

                self?.performFrame()

            }

    }

    // ========================================================

    // MARK: Stop

    // ========================================================

    func stop() {

        running = false

        timer?.invalidate()

        timer = nil

    }

    // ========================================================

    // MARK: Frame

    // ========================================================

    private func performFrame() {

        for _ in 0..<QRTLConstants.physicsStepsPerFrame {

            updatePhysics(

                dt: QRTLConstants.timeStep

            )

        }

        updateScene()

        objectWillChange.send()

    }

    // ========================================================

    // MARK: Physics

    // ========================================================

    private func updatePhysics(

        dt: Double

    ) {

        simulationTime += dt

        if !collisionOccurred {

            updateProtonApproach(

                dt: dt

            )

            updateShellApproach()

            if protonDistance <=

                QRTLConstants.collisionDistance {

                performCollision()

            }

            return

        }

        updateShellState(

            dt: dt

        )

        updateLattice(

            dt: dt

        )

        measureCollectiveMode()

        recordCollectiveLatticeSignal()

        updateHiggsLikeMode(

            dt: dt

        )

    }

    // ========================================================

    // MARK: Proton Approach

    // ========================================================

    private func updateProtonApproach(

        dt: Double

    ) {

        protonAX +=

            QRTLConstants.protonSpeed * dt

        protonBX -=

            QRTLConstants.protonSpeed * dt

        protonANode.position.x =

            Float(protonAX) *

            QRTLConstants.sceneScale

        protonBNode.position.x =

            Float(protonBX) *

            QRTLConstants.sceneScale

        protonDistance =

            abs(

                protonBX -

                protonAX

            )

        protonAState = "MOVING"

        protonBState = "MOVING"

    }

    // ========================================================

    // MARK: Shell Approach

    // ========================================================

    private func updateShellApproach() {

        let separation =

            max(

                protonDistance,

                QRTLConstants.collisionDistance

            )

        let compression =

            max(

                0,

                1.0 -

                separation / 12.0

            )

        let scale =

            Float(

                1.0 +

                compression * 0.35

            )

        protonAShellNode.scale =

            SCNVector3(

                scale,

                scale,

                scale

            )

        protonBShellNode.scale =

            SCNVector3(

                scale,

                scale,

                scale

            )

    }

    // ========================================================

    // MARK: Collision

    // ========================================================

    private func performCollision() {
        guard !collisionOccurred else { return }

        collisionOccurred = true
        protonAState = "COLLIDED"
        protonBState = "COLLIDED"
        collisionTime = simulationTime

        protonAX = -0.275
        protonBX = 0.275
        protonANode.position.x = Float(protonAX) * QRTLConstants.sceneScale
        protonBNode.position.x = Float(protonBX) * QRTLConstants.sceneScale
        protonDistance = abs(protonBX - protonAX)

        collisionKineticEnergyJ = QRTLConstants.collisionKineticEnergyJ
        collisionKineticEnergyGeV = collisionKineticEnergyJ / QRTLConstants.joulePerGeV
        collisionKineticEnergyTeV = collisionKineticEnergyGeV / 1_000.0
        energyState.kineticEnergy = collisionKineticEnergyJ

        formationThresholdEnergy =
            energyState.equilibriumShellEnergy + collisionKineticEnergyJ
        energyState.shellEnergy = formationThresholdEnergy
        energyState.deformation = 1.0
        energyState.shellInstability = 1.0
        energyState.isUnstable = true

        exciteLatticeFromCollision()

        protonANode.isHidden = true
        protonBNode.isHidden = true
        protonAShellNode.isHidden = true
        protonBShellNode.isHidden = true
        protonAState = "DISPERSED → QUARK/CHARGE LATTICE"
        protonBState = "DISPERSED → QUARK/CHARGE LATTICE"

        print("""
        ====================================================
        QRTL PROTON COLLISION
        ====================================================
        Collision kinetic energy:
          \(String(format: "%.6e", collisionKineticEnergyJ)) J
          \(String(format: "%.3f", collisionKineticEnergyGeV)) GeV
          \(String(format: "%.6f", collisionKineticEnergyTeV)) TeV
        ====================================================
        """)
    }

    // ========================================================
    // MARK: Collision -> Lattice Excitation
    // ========================================================

    private func exciteLatticeFromCollision() {
        let radius = QRTLConstants.excitationRadius
        let radiusSquared = radius * radius
        var candidates: [(index: Int, weight: Double, direction: SIMD3<Float>)] = []
        var totalWeight = 0.0

        for index in cells.indices {
            let position = cells[index].position
            let distanceSquared = Double(simd_length_squared(position))
            guard distanceSquared <= radiusSquared else { continue }
            let distance = sqrt(distanceSquared)
            let weight = max(0.0, 1.0 - distance / radius)
            guard weight > 0 else { continue }
            let length = simd_length(position)
            let direction = length > 0.0001 ? position / length : SIMD3<Float>(1, 0, 0)
            candidates.append((index, weight, direction))
            totalWeight += weight
        }

        guard totalWeight > 0 else { return }
        initialAffectedCellCount = candidates.count

        var totalDepositedEnergy = 0.0
        var peakEnergy = 0.0
        var weightedRadius = 0.0

        for candidate in candidates {
            let share = collisionKineticEnergyJ * candidate.weight / totalWeight
            let potentialEnergy = share * QRTLConstants.collisionKineticFractionToPotential
            let kineticEnergy = share - potentialEnergy

            let physicalDisplacement = sqrt(
                max(0.0, 2.0 * potentialEnergy / QRTLConstants.effectiveStiffnessNPerM)
            )
            let physicalVelocity = sqrt(
                max(0.0, 2.0 * kineticEnergy / QRTLConstants.effectiveMassKg)
            )

            let latticeDisplacement = physicalDisplacement / QRTLConstants.latticeCellSpacingMeters
            let latticeVelocity = physicalVelocity / QRTLConstants.latticeCellSpacingMeters
            let index = candidate.index

            cells[index].modeDirection = candidate.direction
            cells[index].displacement = candidate.direction * Float(latticeDisplacement)
            cells[index].velocity = candidate.direction * Float(latticeVelocity)
            cells[index].modeCoordinate = latticeDisplacement
            cells[index].modeVelocity = latticeVelocity
            cells[index].modeAcceleration = 0
            cells[index].amplitude = latticeDisplacement
            cells[index].localStrain = min(1.0, latticeDisplacement)
            cells[index].couplingState = min(1.0, candidate.weight)
            cells[index].localEnergy = share

            let omega = sqrt(
                QRTLConstants.effectiveStiffnessNPerM /
                QRTLConstants.effectiveMassKg
            )
            cells[index].phase = atan2(
                physicalVelocity,
                max(omega * physicalDisplacement, 1.0e-300)
            )
            cells[index].previousPhase = cells[index].phase
            cells[index].unwrappedPhase = cells[index].phase

            totalDepositedEnergy += share
            peakEnergy = max(peakEnergy, share)
            weightedRadius += distanceForCell(cells[index]) * share
        }

        depositedEnergyJ = totalDepositedEnergy
        depositedEnergyGeV = totalDepositedEnergy / QRTLConstants.joulePerGeV
        depositedEnergyTeV = depositedEnergyGeV / 1_000.0
        peakCellEnergyGeV = peakEnergy / QRTLConstants.joulePerGeV
        peakEnergyFraction = totalDepositedEnergy > 0 ? peakEnergy / totalDepositedEnergy : 0
        energyRadius = totalDepositedEnergy > 0 ? weightedRadius / totalDepositedEnergy : 0

        latticeEnergy = totalMechanicalLatticeEnergy()
        currentLatticeEnergyJ = latticeEnergy
        currentLatticeEnergyGeV = latticeEnergy / QRTLConstants.joulePerGeV
        currentLatticeEnergyTeV = currentLatticeEnergyGeV / 1_000.0
        dissipatedEnergyJ = max(0.0, depositedEnergyJ - latticeEnergy)
        dissipatedEnergyGeV = dissipatedEnergyJ / QRTLConstants.joulePerGeV
        dissipatedEnergyTeV = dissipatedEnergyGeV / 1_000.0
        updateEnergyBalance()
        latticeExcited = totalDepositedEnergy > 0

        print("""
        ====================================================
        INITIAL LATTICE EXCITATION
        ====================================================
        Active cells:
          \(initialAffectedCellCount)
        Deposited energy:
          \(String(format: "%.6e", depositedEnergyJ)) J
        Peak cell energy:
          \(String(format: "%.6e", peakEnergy)) J
        Peak / total:
          \(String(format: "%.6f", peakEnergyFraction))
        Energy radius:
          \(String(format: "%.4f", energyRadius))
        ====================================================
        """)
    }

    private func distanceForCell(_ cell: QRTLCell) -> Double {
        Double(simd_length(cell.position))
    }

    private func physicalEnergy(
        displacement: SIMD3<Float>,
        velocity: SIMD3<Float>
    ) -> Double {
        let spacing = QRTLConstants.latticeCellSpacingMeters
        let x = Double(simd_length(displacement)) * spacing
        let v = Double(simd_length(velocity)) * spacing
        let potential = 0.5 * QRTLConstants.effectiveStiffnessNPerM * x * x
        let kinetic = 0.5 * QRTLConstants.effectiveMassKg * v * v
        return max(0.0, potential + kinetic)
    }

    private func totalMechanicalLatticeEnergy() -> Double {
        cells.reduce(0.0) { total, cell in
            total + physicalEnergy(displacement: cell.displacement, velocity: cell.velocity)
        }
    }

    private func updateEnergyBalance() {
        currentLatticeEnergyJ = latticeEnergy
        currentLatticeEnergyGeV = latticeEnergy / QRTLConstants.joulePerGeV
        currentLatticeEnergyTeV = currentLatticeEnergyGeV / 1_000.0
        let accounted = currentLatticeEnergyJ + dissipatedEnergyJ
        energyBalanceErrorJ = collisionKineticEnergyJ - accounted
        energyBalanceErrorGeV = energyBalanceErrorJ / QRTLConstants.joulePerGeV
    }

    // MARK: Shell Dynamics

    // ========================================================

    private func updateShellState(

        dt: Double

    ) {

        if !energyState.isUnstable {

            return

        }

        // Shell instability begins high and relaxes as energy

        // is transferred into collective lattice motion.

        let transferRate =
            QRTLConstants.shellRelaxationRatePerSecond * dt

        energyState.shellInstability =
            max(0.0, energyState.shellInstability - transferRate)

        energyState.deformation =

            energyState.shellInstability

        energyState.shellEnergy =

            formationThresholdEnergy *

            (

                0.25 +

                0.75 *

                energyState.shellInstability

            )

        if energyState.shellInstability < 0.05 {

            energyState.isUnstable = false

        }

        let visualScale =

            Float(

                1.0 +

                energyState.shellInstability *

                0.9

            )

        protonAShellNode.scale =

            SCNVector3(

                visualScale,

                visualScale,

                visualScale

            )

        protonBShellNode.scale =

            SCNVector3(

                visualScale,

                visualScale,

                visualScale

            )

    }

    // ========================================================

    // MARK: Lattice Dynamics

    // ========================================================

    private func updateLattice(
        dt: Double
    ) {
        guard !cells.isEmpty else {
            return
        }

        let previousEnergy = totalMechanicalLatticeEnergy()

        var nextCells = cells

        // --------------------------------------------------------
        // QRTL mechanical constants
        // --------------------------------------------------------

        let stiffness =
            QRTLConstants.effectiveStiffnessNPerM

        let mass =
            QRTLConstants.effectiveMassKg

        let stiffnessOverMass =
            stiffness / mass

        let coupling =
            QRTLConstants.coupling

        let couplingAcceleration =
            coupling * stiffnessOverMass

        let dampingRate =
            QRTLConstants.dampingRatePerSecond

        let dampingFactor =
            exp(-dampingRate * dt)

        let omega =
            sqrt(max(stiffnessOverMass, 0.0))

        // --------------------------------------------------------
        // Synchronous CA update
        //
        // Every calculation reads from `cells`.
        // Every result is written to `nextCells`.
        // --------------------------------------------------------

        for index in cells.indices {

            let cell =
                cells[index]

            // ----------------------------------------------------
            // Neighbor averages
            // ----------------------------------------------------

            var neighborDisplacement =
                SIMD3<Float>(0, 0, 0)

            var neighborTwist =
                0.0

            var neighborStrain =
                0.0

            for neighborIndex in cell.neighbors {

                let neighbor =
                    cells[neighborIndex]

                neighborDisplacement +=
                    neighbor.displacement

                neighborTwist +=
                    neighbor.twist

                neighborStrain +=
                    neighbor.localStrain
            }

            if !cell.neighbors.isEmpty {

                let neighborCount =
                    Double(cell.neighbors.count)

                let neighborCountFloat =
                    Float(neighborCount)

                neighborDisplacement /=
                    neighborCountFloat

                neighborTwist /=
                    neighborCount

                neighborStrain /=
                    neighborCount
            }

            // ----------------------------------------------------
            // Mechanical restoring force
            //
            // F = -kx
            // a = F/m = -(k/m)x
            // ----------------------------------------------------

            let restoring =
                -Float(stiffnessOverMass) *
                cell.displacement

            // ----------------------------------------------------
            // Neighbor coupling
            // ----------------------------------------------------

            let displacementDifference =
                neighborDisplacement -
                cell.displacement

            let neighborForce =
                Float(couplingAcceleration) *
                displacementDifference

            let acceleration =
                restoring +
                neighborForce

            // ----------------------------------------------------
            // Velocity
            // ----------------------------------------------------

            var newVelocity =
                cell.velocity +
                acceleration * Float(dt)

            newVelocity *=
                Float(dampingFactor)

            // ----------------------------------------------------
            // Displacement
            // ----------------------------------------------------

            var newDisplacement =
                cell.displacement +
                newVelocity * Float(dt)

            // ----------------------------------------------------
            // Numerical protection
            // ----------------------------------------------------

            let displacementFinite =
                newDisplacement.x.isFinite &&
                newDisplacement.y.isFinite &&
                newDisplacement.z.isFinite

            let velocityFinite =
                newVelocity.x.isFinite &&
                newVelocity.y.isFinite &&
                newVelocity.z.isFinite

            if !displacementFinite ||
                !velocityFinite {

                newDisplacement =
                    SIMD3<Float>(0, 0, 0)

                newVelocity =
                    SIMD3<Float>(0, 0, 0)
            }

            // ----------------------------------------------------
            // Twist dynamics
            // ----------------------------------------------------

            let twistDifference =
                neighborTwist -
                cell.twist

            let twistCoupling =
                QRTLConstants.twistCoupling *
                twistDifference

            let twistRestoring =
                QRTLConstants.twistRestoring *
                cell.twist

            let twistAcceleration =
                twistCoupling -
                twistRestoring

            var newTwist =
                cell.twist +
                twistAcceleration * dt

            newTwist *=
                dampingFactor

            // ----------------------------------------------------
            // Collective mode direction
            // ----------------------------------------------------

            let modeDirectionLength =
                simd_length(cell.modeDirection)

            let direction: SIMD3<Float>

            if modeDirectionLength > 0.0001 {

                direction =
                    cell.modeDirection

            } else {

                direction =
                    SIMD3<Float>(1, 0, 0)
            }

            // ----------------------------------------------------
            // Mode coordinate
            // ----------------------------------------------------

            let modeCoordinateFloat =
                simd_dot(
                    newDisplacement,
                    direction
                )

            let modeVelocityFloat =
                simd_dot(
                    newVelocity,
                    direction
                )

            let modeCoordinate =
                Double(modeCoordinateFloat)

            let modeVelocity =
                Double(modeVelocityFloat)

            // ----------------------------------------------------
            // Physical displacement
            // ----------------------------------------------------

            let cellSpacing =
                QRTLConstants.latticeCellSpacingMeters

            let xMeters =
                abs(modeCoordinate) *
                cellSpacing

            let vMetersPerSecond =
                abs(modeVelocity) *
                cellSpacing

            // ----------------------------------------------------
            // Phase
            // ----------------------------------------------------

            let omegaSafe =
                max(omega, 1.0e-300)

            let phaseDenominator =
                max(
                    omegaSafe * xMeters,
                    1.0e-300
                )

            let phaseMagnitude =
                atan2(
                    vMetersPerSecond,
                    phaseDenominator
                )

            let phaseSign =
                modeVelocity >= 0.0
                    ? 1.0
                    : -1.0

            let phase =
                phaseMagnitude * phaseSign

            let phaseDifference =
                phase -
                cell.phase

            let phaseChange =
                wrapPhase(phaseDifference)

            let newUnwrappedPhase =
                cell.unwrappedPhase +
                phaseChange

            // ----------------------------------------------------
            // Amplitude
            //
            // Dimensionless lattice-mode amplitude.
            // It is NOT treated as energy.
            // ----------------------------------------------------

            let normalizedVelocity =
                modeVelocity /
                omegaSafe

            let coordinateSquared =
                modeCoordinate *
                modeCoordinate

            let velocitySquared =
                normalizedVelocity *
                normalizedVelocity

            let amplitudeSquared =
                coordinateSquared +
                velocitySquared

            let amplitude =
                sqrt(
                    max(
                        amplitudeSquared,
                        0.0
                    )
                )

            // ----------------------------------------------------
            // Strain
            // ----------------------------------------------------

            let displacementMagnitude =
                Double(
                    simd_length(
                        newDisplacement
                    )
                )

            let baseStrain =
                min(
                    1.0,
                    displacementMagnitude
                )

            let strainDifference =
                abs(
                    neighborStrain -
                    baseStrain
                )

            let propagatedStrain =
                strainDifference *
                QRTLConstants.strainCoupling

            let newStrain =
                min(
                    1.0,
                    baseStrain +
                    propagatedStrain
                )

            // ----------------------------------------------------
            // Physical cell energy
            //
            // U = 1/2 kx²
            // K = 1/2 mv²
            // E = U + K
            // ----------------------------------------------------

            let energy =
                physicalEnergy(
                    displacement: newDisplacement,
                    velocity: newVelocity
                )

            // ----------------------------------------------------
            // Coupling state
            // ----------------------------------------------------

            let displacementDifferenceX =
                abs(
                    Double(
                        neighborDisplacement.x -
                        cell.displacement.x
                    )
                )

            let couplingIncrease =
                coupling *
                displacementDifferenceX *
                dt

            let updatedCouplingState =
                cell.couplingState +
                couplingIncrease

            let newCouplingState =
                min(
                    1.0,
                    max(
                        0.0,
                        updatedCouplingState
                    )
                )

            // ----------------------------------------------------
            // Write next state
            // ----------------------------------------------------

            nextCells[index].displacement =
                newDisplacement

            nextCells[index].velocity =
                newVelocity

            nextCells[index].modeCoordinate =
                modeCoordinate

            nextCells[index].modeVelocity =
                modeVelocity

            nextCells[index].modeAcceleration =
                Double(
                    simd_length(acceleration)
                )

            nextCells[index].twist =
                newTwist

            nextCells[index].previousPhase =
                cell.phase

            nextCells[index].phase =
                phase

            nextCells[index].unwrappedPhase =
                newUnwrappedPhase

            nextCells[index].amplitude =
                amplitude

            nextCells[index].localStrain =
                newStrain

            nextCells[index].couplingState =
                newCouplingState

            nextCells[index].localEnergy =
                energy
        }

        // --------------------------------------------------------
        // Commit synchronous CA state
        // --------------------------------------------------------

        cells =
            nextCells

        // --------------------------------------------------------
        // Physical lattice energy
        // --------------------------------------------------------

        latticeEnergy =
            totalMechanicalLatticeEnergy()

        // --------------------------------------------------------
        // Energy accounting
        // --------------------------------------------------------

        dissipatedEnergyJ =
            max(
                0.0,
                depositedEnergyJ -
                latticeEnergy
            )

        dissipatedEnergyGeV =
            dissipatedEnergyJ /
            QRTLConstants.joulePerGeV

        dissipatedEnergyTeV =
            dissipatedEnergyGeV /
            1_000.0

        updateEnergyBalance()

        // --------------------------------------------------------
        // Spatial response statistics
        // --------------------------------------------------------

        let cellCount =
            Double(
                max(
                    cells.count,
                    1
                )
            )

        var strainTotal =
            0.0

        var twistTotal =
            0.0

        for cell in cells {

            strainTotal +=
                cell.localStrain

            twistTotal +=
                abs(cell.twist)
        }

        averageStrain =
            strainTotal /
            cellCount

        averageTwist =
            twistTotal /
            cellCount

        // --------------------------------------------------------
        // Collective amplitude
        //
        // IMPORTANT:
        // This uses the entire lattice.
        //
        // It is weighted by physical cell energy,
        // but amplitude itself is NOT energy.
        // --------------------------------------------------------

        var amplitudeEnergySum =
            0.0

        var amplitudeWeight =
            0.0

        for cell in cells {

            let cellEnergy =
                max(
                    cell.localEnergy,
                    0.0
                )

            let cellAmplitude =
                cell.amplitude

            let amplitudeSquared =
                cellAmplitude *
                cellAmplitude

            amplitudeEnergySum +=
                cellEnergy *
                amplitudeSquared

            amplitudeWeight +=
                cellEnergy
        }

        if amplitudeWeight > 0.0 {

            let weightedAmplitudeSquared =
                amplitudeEnergySum /
                amplitudeWeight

            collectiveAmplitude =
                sqrt(
                    max(
                        weightedAmplitudeSquared,
                        0.0
                    )
                )

        } else {

            collectiveAmplitude =
                0.0
        }

        peakCollectiveAmplitude =
            max(
                peakCollectiveAmplitude,
                collectiveAmplitude
            )

        // --------------------------------------------------------
        // Coherence is independent of amplitude
        // --------------------------------------------------------

        calculateCollectiveCoherence()

        // --------------------------------------------------------
        // Active lattice state
        // --------------------------------------------------------

        latticeExcited =
            latticeEnergy >
            QRTLConstants.activeEnergyThresholdJ

        // --------------------------------------------------------
        // Time-dependent response
        // --------------------------------------------------------

        propagationTime =
            max(
                0.0,
                simulationTime -
                collisionTime
            )

        let spectralCount =
            Double(
                max(
                    spectralSampleCount,
                    0
                )
            )

        let requiredSamples =
            Double(
                max(
                    QRTLConstants.spectralSampleCount,
                    1
                )
            )

        resonanceDevelopment =
            min(
                1.0,
                spectralCount /
                requiredSamples
            )

        dampingFraction =
            depositedEnergyJ > 0.0
                ? min(
                    1.0,
                    dissipatedEnergyJ /
                    depositedEnergyJ
                )
                : 0.0

        returnedToEquilibrium =
            latticeEnergy <=
            QRTLConstants.activeEnergyThresholdJ &&
            propagationTime > 0.0

        // --------------------------------------------------------
        // Retain previous energy as a diagnostic reference.
        // --------------------------------------------------------

        _ =
            previousEnergy
    }

    // MARK: Collective Coherence

    // ========================================================

    private func calculateCollectiveCoherence() {
        guard !cells.isEmpty else {
            collectiveCoherence = 0
            resonantModeEnergyJ = 0
            resonantModeEnergyGeV = 0
            resonantModeEnergyTeV = 0
            resonantModeEnergy = 0
            return
        }

        var real = 0.0
        var imaginary = 0.0
        var totalWeight = 0.0

        for cell in cells {
            let weight = max(cell.localEnergy, 0.0)
            guard weight > QRTLConstants.activeEnergyThresholdJ else { continue }
            real += weight * cos(cell.phase)
            imaginary += weight * sin(cell.phase)
            totalWeight += weight
        }

        guard totalWeight > 0 else {
            collectiveCoherence = 0
            resonantModeEnergyJ = 0
            resonantModeEnergyGeV = 0
            resonantModeEnergyTeV = 0
            resonantModeEnergy = 0
            return
        }

        collectiveCoherence = min(
            1.0,
            sqrt(real * real + imaginary * imaginary) / totalWeight
        )

        // Resonant-mode energy is a partition of existing lattice
        // mechanical energy. It never adds energy to the system.
        resonantModeEnergyJ =
            latticeEnergy * collectiveCoherence * collectiveCoherence
        resonantModeEnergyGeV =
            resonantModeEnergyJ / QRTLConstants.joulePerGeV
        resonantModeEnergyTeV = resonantModeEnergyGeV / 1_000.0
        resonantModeEnergy = resonantModeEnergyJ
    }

    // MARK: Record Collective Lattice Signal
    // ========================================================

    private func recordCollectiveLatticeSignal() {
        guard collisionOccurred, !cells.isEmpty else { return }
        var weightedDisplacement = 0.0
        var totalEnergy = 0.0
        for cell in cells {
            let energy = max(cell.localEnergy, 0.0)
            guard energy > 1.0e-12 else { continue }
            weightedDisplacement += energy * cell.modeCoordinate
            totalEnergy += energy
        }
        guard totalEnergy > 1.0e-12 else { return }
        spectralAnalyzer.append(weightedDisplacement / totalEnergy)
        spectralSampleCount = spectralAnalyzer.samples.count
        spectralNyquistHz = 0.5 / QRTLConstants.timeStep
        if spectralAnalyzer.samples.count >= QRTLConstants.spectralSampleCount,
           let spectral = spectralAnalyzer.analyze(sampleInterval: QRTLConstants.timeStep) {
            resonantFrequencyHz = spectral.frequencyHz
            resonantAngularFrequency = spectral.angularFrequency
            resonantWavelengthMeters = spectral.wavelengthMeters
            spectralPeakAmplitude = spectral.peakAmplitude
            spectralAnalysisComplete = true
        }
    }

    // MARK: Measure Collective Mode

    // ========================================================

    //

    // The resonant frequency is now measured from repeated

    // motion of the lattice.

    //

    // No energy -> mass shortcut is used.

    //

    // The algorithm:

    //

    // 1. Build a weighted collective displacement signal.

    // 2. Detect repeated zero crossings.

    // 3. Measure the period between equivalent crossings.

    // 4. Frequency = 1 / period.

    //

    // This means frequency cannot become nonzero unless the

    // lattice actually oscillates.

    // ========================================================

    private func measureCollectiveMode() {

        var weightedSignal = 0.0

        var weightedVelocity = 0.0

        var totalWeight = 0.0

        for cell in cells {

            let weight =

                max(

                    cell.localEnergy,

                    0

                ) +

                cell.amplitude *

                cell.amplitude

            guard weight > QRTLConstants.activeEnergyThresholdJ else {

                continue

            }

            weightedSignal +=

                cell.modeCoordinate *

                weight

            weightedVelocity +=

                cell.modeVelocity *

                weight

            totalWeight +=

                weight

        }

        guard totalWeight > 0 else {

            return

        }

        let collectiveSignal =

            weightedSignal /

            totalWeight

        let collectiveVelocity =

            weightedVelocity /

            totalWeight

        // ----------------------------------------------------

        // Save the initial state.

        // ----------------------------------------------------

        if !phaseReferenceEstablished {

            previousCollectiveSignal =

                collectiveSignal

            previousCollectiveVelocity =

                collectiveVelocity

            phaseReferenceEstablished = true

            return

        }

        // ----------------------------------------------------

        // Positive-going zero crossing:

        //

        // previous signal <= 0

        // current signal > 0

        // velocity > 0

        // ----------------------------------------------------

        let positiveCrossing =

            previousCollectiveSignal <= 0 &&

            collectiveSignal > 0 &&

            collectiveVelocity > 0

        if positiveCrossing {

            if let previousCrossing =

                lastPositiveCrossingTime {

                let period =

                    simulationTime -

                    previousCrossing

                if period > 0.000001 &&

                    period.isFinite {

                    measuredPeriods.append(

                        period

                    )

                    // Keep only recent periods so that the

                    // resonant frequency follows the current

                    // lattice state.

                    if measuredPeriods.count > 8 {

                        measuredPeriods.removeFirst()

                    }

                    let averagePeriod =

                        measuredPeriods.reduce(

                            0,

                            +

                        ) /

                        Double(

                            measuredPeriods.count

                        )

                    if averagePeriod > 0 {

                        resonantFrequencyHz =

                            1.0 /

                            averagePeriod

                    }

                }

            }

            lastPositiveCrossingTime =

                simulationTime

        }

        previousCollectiveSignal =

            collectiveSignal

        previousCollectiveVelocity =

            collectiveVelocity

    }

    // ========================================================

    // MARK: Resonant Frequency -> Mass

    // ========================================================

    //

    // E = h f

    //

    // E is derived from the measured oscillation frequency.

    //

    // E is then converted to GeV.

    //

    // No artificial "energy * 125" conversion exists.

    // ========================================================

    private func massFromFrequency(

        _ frequencyHz: Double

    ) -> Double {

        guard frequencyHz.isFinite,

              frequencyHz > 0

        else {

            return 0

        }

        let energyJoules =

            QRTLConstants.planckConstant *

            frequencyHz

        let energyGeV =

            energyJoules /

            QRTLConstants.joulePerGeV

        return energyGeV

    }

    // ========================================================

    // MARK: Higgs-Like Mode

    // ========================================================

    private func updateHiggsLikeMode(
        dt: Double
    ) {
        higgsMode.age += dt
        calculateCollectiveCoherence()

        var weightedAmplitude = 0.0
        var phaseReal = 0.0
        var phaseImaginary = 0.0
        var phaseWeight = 0.0

        for cell in cells {
            let weight = max(cell.localEnergy, 0.0)
            guard weight > QRTLConstants.activeEnergyThresholdJ else { continue }
            weightedAmplitude += abs(cell.modeCoordinate) * weight
            phaseReal += weight * cos(cell.phase)
            phaseImaginary += weight * sin(cell.phase)
            phaseWeight += weight
        }

        let modeAmplitude = phaseWeight > 0
            ? weightedAmplitude / phaseWeight
            : 0
        let modeCoherence = phaseWeight > 0
            ? min(1.0, sqrt(phaseReal * phaseReal + phaseImaginary * phaseImaginary) / phaseWeight)
            : 0

        resonantMassGeV = massFromFrequency(resonantFrequencyHz)
        massDistanceFromTarget = abs(QRTLConstants.targetHiggsMassGeV - resonantMassGeV)
        higgsMode.frequencyHz = resonantFrequencyHz
        higgsMode.massGeV = resonantMassGeV
        higgsMode.energy = resonantModeEnergyJ
        higgsMode.amplitude = modeAmplitude
        higgsMode.coherence = modeCoherence
        higgsMode.shellEnergy = energyState.shellEnergy
        higgsMode.shellInstability = energyState.shellInstability

        let sufficientEnergy = resonantModeEnergyJ > QRTLConstants.activeEnergyThresholdJ
        let sufficientCoherence = modeCoherence > 0.50
        let measuredFrequency = resonantFrequencyHz > 0
        let shellWasDestabilized = formationThresholdEnergy > energyState.equilibriumShellEnergy

        higgsMode.active =
            collisionOccurred &&
            sufficientEnergy &&
            sufficientCoherence &&
            measuredFrequency &&
            shellWasDestabilized

        if higgsMode.active {
            higgsNode.isHidden = false
            let visualScale = Float(max(0.05, min(2.5, modeAmplitude * 8.0)))
            higgsNode.scale = SCNVector3(visualScale, visualScale, visualScale)
            higgsNode.opacity = CGFloat(max(0.15, min(1.0, modeCoherence)))
        } else {
            higgsNode.isHidden = true
        }

        if !energyState.isUnstable && higgsMode.active {
            higgsMode.decayProgress = min(1.0, higgsMode.decayProgress + dt * 0.15)
            if higgsMode.decayProgress >= 1.0 {
                higgsMode.active = false
                higgsNode.isHidden = true
            }
        }
    }

    // ========================================================

    // MARK: Scene Update

    // ========================================================

    private func updateScene() {

        for index in cells.indices {

            let cell =

                cells[index]

            let node =

                cellNodes[index]

            let displacement =

                cell.displacement

            let position =

                cell.position

            node.position =

                SCNVector3(

                    (

                        position.x +

                        displacement.x

                    ) *

                    QRTLConstants.sceneScale,

                    (

                        position.y +

                        displacement.y

                    ) *

                    QRTLConstants.sceneScale,

                    (

                        position.z +

                        displacement.z

                    ) *

                    QRTLConstants.sceneScale

                )

            // ------------------------------------------------

            // Energy controls visibility and size.

            // ------------------------------------------------

            let energy =

                min(

                    1.0,

                    cell.localEnergy

                )

            let amplitude =

                min(

                    1.0,

                    cell.amplitude * 5.0

                )

            let scale =

                Float(

                    0.5 +

                    amplitude * 1.8

                )

            node.scale =

                SCNVector3(

                    scale,

                    scale,

                    scale

                )

            if let material =

                node.geometry?.firstMaterial {

                material.diffuse.contents =

                    UIColor(

                        red: CGFloat(

                            min(

                                1.0,

                                energy * 2.0

                            )

                        ),

                        green: CGFloat(

                            min(

                                1.0,

                                0.25 +

                                cell.couplingState

                            )

                        ),

                        blue: CGFloat(

                            min(

                                1.0,

                                0.35 +

                                collectiveCoherence

                            )

                        ),

                        alpha: CGFloat(

                            0.25 +

                            energy * 0.75

                        )

                    )

            }

        }

        // ----------------------------------------------------

        // Keep protons visible at collision.

        // ----------------------------------------------------

        protonANode.position.x =

            Float(protonAX) *

            QRTLConstants.sceneScale

        protonBNode.position.x =

            Float(protonBX) *

            QRTLConstants.sceneScale

        // ----------------------------------------------------

        // Higgs-like visual mode

        // ----------------------------------------------------

        if !higgsNode.isHidden {

            let pulse =

                1.0 +

                0.25 *

                sin(

                    simulationTime *

                    10.0

                )

            let scale =

                Float(

                    max(

                        0.05,

                        higgsMode.amplitude *

                        10.0

                    )

                ) *

                Float(pulse)

            higgsNode.scale =

                SCNVector3(

                    scale,

                    scale,

                    scale

                )

        }

    }

    // ========================================================

    // MARK: Reset

    // ========================================================

    func reset() {

        stop()

        simulationTime = 0

        protonAX =

            -QRTLConstants.initialProtonX

        protonBX =

            QRTLConstants.initialProtonX

        protonDistance =

            abs(

                protonBX -

                protonAX

            )

        collisionOccurred = false

        latticeExcited = false

        protonAState = "MOVING"

        protonBState = "MOVING"

        energyState =

            QRTLEnergyState()

        higgsMode =

            HiggsLikeMode()

        collectiveCoherence = 0

        collectiveAmplitude = 0

        averageStrain = 0

        averageTwist = 0

        latticeEnergy = 0

        resonantModeEnergy = 0

        resonantFrequencyHz = 0
        resonantAngularFrequency = 0
        resonantWavelengthMeters = 0
        spectralPeakAmplitude = 0
        spectralSampleCount = 0
        spectralNyquistHz = 0
        spectralAnalysisComplete = false
        spectralAnalyzer.reset()

        collisionKineticEnergyJ = 0
        collisionKineticEnergyGeV = 0
        collisionKineticEnergyTeV = 0
        depositedEnergyJ = 0
        depositedEnergyGeV = 0
        depositedEnergyTeV = 0
        currentLatticeEnergyJ = 0
        currentLatticeEnergyGeV = 0
        currentLatticeEnergyTeV = 0
        resonantModeEnergyJ = 0
        resonantModeEnergyGeV = 0
        resonantModeEnergyTeV = 0
        dissipatedEnergyJ = 0
        dissipatedEnergyGeV = 0
        dissipatedEnergyTeV = 0
        energyBalanceErrorJ = 0
        energyBalanceErrorGeV = 0
        initialAffectedCellCount = 0
        energyRadius = 0
        peakCellEnergyGeV = 0
        peakEnergyFraction = 0
        peakCollectiveAmplitude = 0
        propagationTime = 0
        resonanceDevelopment = 0
        dampingFraction = 0
        returnedToEquilibrium = false

        resonantMassGeV = 0

        formationThresholdEnergy = 0

        massDistanceFromTarget =

            QRTLConstants.targetHiggsMassGeV

        previousCollectiveSignal = 0

        previousCollectiveVelocity = 0

        lastPositiveCrossingTime = nil

        measuredPeriods.removeAll()

        phaseReferenceEstablished = false

        protonANode.position =

            SCNVector3(

                Float(protonAX) *

                    QRTLConstants.sceneScale,

                0,

                0

            )

        protonBNode.position =

            SCNVector3(

                Float(protonBX) *

                    QRTLConstants.sceneScale,

                0,

                0

            )

        protonAShellNode.scale =

            SCNVector3(

                1,

                1,

                1

            )

        protonBShellNode.scale =

            SCNVector3(

                1,

                1,

                1

            )

        higgsNode.isHidden = true

        buildLattice()

        start()

    }

    // ========================================================

    // MARK: Utilities

    // ========================================================

    private func wrapPhase(

        _ phase: Double

    ) -> Double {

        var result = phase

        while result > Double.pi {

            result -=

                2.0 * Double.pi

        }

        while result < -Double.pi {

            result +=

                2.0 * Double.pi

        }

        return result

    }

}
