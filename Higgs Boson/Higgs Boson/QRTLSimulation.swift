//
//  File.swift
//  Higgs Boson
//
//  Created by David Nishimoto on 9/21/26.
//

import Foundation
import SwiftUI
import Combine
import SceneKit

// MARK: - QRTL SIMULATION

// ============================================================

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

            if cell.localEnergy > 0.000001 {

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

    // MARK: Collision -> Lattice Oscillation

    // ========================================================

    // ============================================================
    // MARK: - COLLISION ENERGY → QRTL LATTICE
    // ============================================================

    private func exciteLatticeFromCollision() {

         let radius =

             QRTLConstants.excitationRadius

         let radiusSquared =

             radius * radius

         var totalDepositedEnergy = 0.0

         for index in cells.indices {

             let position =

                 cells[index].position

             let distanceSquared =

                 Double(

                     simd_length_squared(

                         position

                     )

                 )

             guard distanceSquared <=

                     radiusSquared

             else {

                 continue

             }

             let distance =

                 sqrt(distanceSquared)

             let radialWeight =

                 max(

                     0.0,

                     1.0 -

                     distance / radius

                 )

             let share =

                 QRTLConstants.collisionEnergy *

                 radialWeight

             guard share > 0 else {

                 continue

             }

             totalDepositedEnergy += share

             // ------------------------------------------------

             // Radial collision direction

             // ------------------------------------------------

             let positionLength =

                 simd_length(position)

             let direction: SIMD3<Float>

             if positionLength > 0.0001 {

                 direction =

                     position /

                     positionLength

             } else {

                 direction =

                     SIMD3<Float>(

                         1,

                         0,

                         0

                     )

             }

             // ------------------------------------------------

             // Energy -> displacement

             // ------------------------------------------------

             let displacementAmount =

                 sqrt(

                     max(

                         share,

                         0

                     )

                 ) * 0.20

             cells[index].displacement +=

                 direction *

                 Float(displacementAmount)

             // ------------------------------------------------

             // Energy -> VELOCITY

             //

             // This is the critical change.

             //

             // The collision is an impulse. The cells are not

             // simply left displaced; they are given motion.

             // ------------------------------------------------

             let impulse =

                 sqrt(

                     max(

                         share,

                         0

                     )

                 ) * 0.80

             cells[index].velocity +=

                 direction *

                 Float(impulse)

             // ------------------------------------------------

             // Genuine oscillator coordinate

             // ------------------------------------------------

             cells[index].modeCoordinate +=

                 displacementAmount

             cells[index].modeVelocity +=

                 impulse

             // ------------------------------------------------

             // Initial local energy

             // ------------------------------------------------

             cells[index].localEnergy +=

                 share

             cells[index].amplitude =

                 max(

                     cells[index].amplitude,

                     displacementAmount

                 )

             cells[index].couplingState =

                 min(

                     1.0,

                     cells[index].couplingState +

                     radialWeight * 0.5

                 )

             cells[index].localStrain =

                 min(

                     1.0,

                     cells[index].localStrain +

                     radialWeight * 0.5

                 )

         }

         latticeExcited =

             totalDepositedEnergy > 0

     }

     // ========================================================

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

             min(

                 0.35,

                 latticeEnergy *

                 0.002

             )

         energyState.shellInstability =

             max(

                 0,

                 energyState.shellInstability -

                 transferRate * dt

             )

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

        updateHiggsLikeMode(

            dt: dt

        )
        recordCollectiveLatticeSignal()

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

    // ============================================================
    // MARK: - PROTON COLLISION
    // ============================================================

    private func performCollision() {

        guard !collisionOccurred else {
            return
        }

        collisionOccurred = true

        protonAState = "COLLIDED"
        protonBState = "COLLIDED"

        collisionTime =
            simulationTime

        protonAX = -0.275
        protonBX = 0.275

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

        // ----------------------------------------------------
        // COLLISION ENERGY
        //
        // Keep the incoming relativistic proton kinetic energy
        // available to the lattice. Do NOT set it to zero.
        //
        // At 6.8 TeV per proton:
        // approximately 13.598 TeV of kinetic energy is
        // available from the two incoming protons.
        // ----------------------------------------------------

        energyState.kineticEnergy =
            QRTLConstants.twoProtonKineticEnergyJ

        // ----------------------------------------------------
        // FORMATION THRESHOLD
        //
        // The equilibrium shell energy is destabilized by the
        // incoming collision energy.
        //
        // This is kept separate from the energy subsequently
        // measured in the collective resonant mode.
        // ----------------------------------------------------

        formationThresholdEnergy =
            energyState.equilibriumShellEnergy +
            energyState.kineticEnergy

        energyState.shellEnergy =
            formationThresholdEnergy

        energyState.deformation =
            1.0

        energyState.shellInstability =
            1.0

        energyState.isUnstable =
            true

        // ----------------------------------------------------
        // COLLISION → QUARK/CHARGE LATTICE
        //
        // The lattice receives the collision energy and converts
        // it into displacement, velocity, strain, and local
        // oscillator excitation.
        //
        // exciteLatticeFromCollision() reads the collision energy
        // directly from energyState.kineticEnergy.
        // ----------------------------------------------------

        exciteLatticeFromCollision()

        // ----------------------------------------------------
        // PROTON DISPERSION
        // ----------------------------------------------------

        protonANode.isHidden =
            true

        protonBNode.isHidden =
            true

        protonAShellNode.isHidden =
            true

        protonBShellNode.isHidden =
            true

        protonAState =
            "DISPERSED → QUARK/CHARGE LATTICE"

        protonBState =
            "DISPERSED → QUARK/CHARGE LATTICE"

        protonAShellNode.scale =
            SCNVector3(
                1.7,
                1.7,
                1.7
            )

        protonBShellNode.scale =
            SCNVector3(
                1.7,
                1.7,
                1.7
            )
    }
  
    private func updateLattice(

        dt: Double

    ) {

        guard !cells.isEmpty else {

            return

        }

        var nextCells = cells

        var calculatedLatticeEnergy = 0.0

        var strainSum = 0.0

        var twistSum = 0.0

        var amplitudeSum = 0.0

        var coherentSum = 0.0


        for index in cells.indices {

            let cell =

                cells[index]

    
            var neighborDisplacement =

                SIMD3<Float>(

                    0,

                    0,

                    0

                )

            var neighborMode =

                0.0

            var neighborPhase =

                0.0

            var neighborTwist =

                0.0

            var neighborStrain =

                0.0

            if !cell.neighbors.isEmpty {

                for neighborIndex in

                    cell.neighbors {

                    let neighbor =

                        cells[neighborIndex]

                    neighborDisplacement +=

                        neighbor.displacement

                    neighborMode +=

                        neighbor.modeCoordinate

                    neighborPhase +=

                        neighbor.phase

                    neighborTwist +=

                        neighbor.twist

                    neighborStrain +=

                        neighbor.localStrain

                }

                let count =

                    Double(

                        cell.neighbors.count

                    )

                neighborDisplacement /=

                    Float(count)

                neighborMode /=

                    count

                neighborPhase /=

                    count

                neighborTwist /=

                    count

                neighborStrain /=

                    count

            }

            // ------------------------------------------------

            // QRTL displacement restoring term

            // ------------------------------------------------

            let displacementRestoring =

                -Float(QRTLConstants.restoringForce) *

                cell.displacement

            // ------------------------------------------------

            // Neighbor coupling

            // ------------------------------------------------

            let displacementCoupling =

                Float(

                    QRTLConstants.coupling

                ) *

                (

                    neighborDisplacement -

                    cell.displacement

                )

            // ------------------------------------------------

            // Strain

            // ------------------------------------------------

            let strain =

                Double(

                    simd_length(

                        cell.displacement

                    )

                )

            // ------------------------------------------------

            // Twist coupling

            // ------------------------------------------------

            let twistDelta =

                neighborTwist -

                cell.twist

            let twistAcceleration =

                QRTLConstants.twistCoupling *

                twistDelta -

                QRTLConstants.twistRestoring *

                cell.twist

            // ------------------------------------------------

            // Phase coupling

            // ------------------------------------------------

            let phaseDelta =

                wrapPhase(

                    neighborPhase -

                    cell.phase

                )

            let phaseAcceleration =

                QRTLConstants.phaseCoupling *

                phaseDelta -

                QRTLConstants.phaseRestoring *

                cell.phase

            // ------------------------------------------------

            // Strain coupling

            // ------------------------------------------------

            let strainCoupling =

                QRTLConstants.strainCoupling *

                (

                    neighborStrain -

                    strain

                )

            // ------------------------------------------------

            // Physical displacement acceleration

            // ------------------------------------------------

            let displacementAcceleration =

                displacementRestoring +

                displacementCoupling

            var newVelocity =

                cell.velocity +

                displacementAcceleration *

                Float(dt)

            // Damping

            newVelocity *=

                Float(

                    max(

                        0,

                        1.0 -

                        QRTLConstants.damping *

                        dt

                    )

                )

            var newDisplacement =

                cell.displacement +

                newVelocity *

                Float(dt)

            // ------------------------------------------------

            // Genuine scalar oscillator

            // ------------------------------------------------

            //

            // This oscillator is coupled to the same QRTL

            // restoring/coupling structure rather than being

            // given an externally prescribed phase.

            // ------------------------------------------------

            let oscillatorRestoring =

                -QRTLConstants.restoringForce *

                cell.modeCoordinate

            let oscillatorCoupling =

                QRTLConstants.coupling *

                (

                    neighborMode -

                    cell.modeCoordinate

                )

            let oscillatorStrainCoupling =

                strainCoupling

            let oscillatorAcceleration =

                oscillatorRestoring +

                oscillatorCoupling +

                oscillatorStrainCoupling

            var newModeVelocity =

                cell.modeVelocity +

                oscillatorAcceleration *

                dt

            newModeVelocity *=

                max(

                    0,

                    1.0 -

                    QRTLConstants.damping *

                    dt

                )

            var newModeCoordinate =

                cell.modeCoordinate +

                newModeVelocity *

                dt

            // ------------------------------------------------

            // Prevent numerical runaway while preserving the

            // oscillatory state.

            // ------------------------------------------------

            if !newModeCoordinate.isFinite {

                newModeCoordinate = 0

            }

            if !newModeVelocity.isFinite {

                newModeVelocity = 0

            }

            if !newDisplacement.x.isFinite ||

                !newDisplacement.y.isFinite ||

                !newDisplacement.z.isFinite {

                newDisplacement =

                    SIMD3<Float>(

                        0,

                        0,

                        0

                    )

                newVelocity =

                    SIMD3<Float>(

                        0,

                        0,

                        0

                    )

            }

            // ------------------------------------------------

            // Twist dynamics

            // ------------------------------------------------

            var newTwist =

                cell.twist +

                twistAcceleration *

                dt

            newTwist *=

                max(

                    0,

                    1.0 -

                    QRTLConstants.damping *

                    dt

                )

            // ------------------------------------------------

            // Phase dynamics

            //

            // IMPORTANT:

            //

            // Phase is no longer initialized from collision

            // energy. It is derived from the actual oscillator

            // state.

            // ------------------------------------------------

            let oscillatorMagnitude =

                sqrt(

                    max(

                        0,

                        QRTLConstants.restoringForce

                    )

                )

            let phase =

                atan2(

                    newModeVelocity,

                    oscillatorMagnitude *

                    newModeCoordinate

                )

            let oldPhase =

                cell.phase

            let phaseChange =

                wrapPhase(

                    phase -

                    oldPhase

                )

            var newUnwrappedPhase =

                cell.unwrappedPhase +

                phaseChange

            if !newUnwrappedPhase.isFinite {

                newUnwrappedPhase = 0

            }

            // ------------------------------------------------

            // Amplitude

            // ------------------------------------------------

            let newAmplitude =

                sqrt(

                    newModeCoordinate *

                    newModeCoordinate +

                    (

                        newModeVelocity /

                        max(

                            oscillatorMagnitude,

                            0.000001

                        )

                    ) *

                    (

                        newModeVelocity /

                        max(

                            oscillatorMagnitude,

                            0.000001

                        )

                    )

                )

            // ------------------------------------------------

            // Local oscillator energy

            // ------------------------------------------------

            let oscillatorEnergy =

                0.5 *

                (

                    newModeVelocity *

                    newModeVelocity

                ) +

                0.5 *

                QRTLConstants.restoringForce *

                (

                    newModeCoordinate *

                    newModeCoordinate

                )

            let displacementEnergy =

                0.5 *

                Double(

                    simd_length_squared(

                        newVelocity

                    )

                ) +

                0.5 *

                QRTLConstants.restoringForce *

                Double(

                    simd_length_squared(

                        newDisplacement

                    )

                )

            let totalCellEnergy =

                max(

                    0,

                    oscillatorEnergy +

                    displacementEnergy

                )

            // ------------------------------------------------

            // Coupling state

            // ------------------------------------------------

            let couplingState =

                min(

                    1.0,

                    max(

                        0,

                        cell.couplingState +

                        (

                            QRTLConstants.coupling *

                            abs(

                                neighborMode -

                                cell.modeCoordinate

                            )

                        ) *

                        dt

                    )

                )

            // ------------------------------------------------

            // Write new cell

            // ------------------------------------------------

            nextCells[index].displacement =

                newDisplacement

            nextCells[index].velocity =

                newVelocity

            nextCells[index].modeCoordinate =

                newModeCoordinate

            nextCells[index].modeVelocity =

                newModeVelocity

            nextCells[index].modeAcceleration =

                oscillatorAcceleration

            nextCells[index].twist =

                newTwist

            nextCells[index].previousPhase =

                oldPhase

            nextCells[index].phase =

                phase

            nextCells[index].unwrappedPhase =

                newUnwrappedPhase

            nextCells[index].amplitude =

                newAmplitude

            nextCells[index].localStrain =

                strain

            nextCells[index].localEnergy =

                totalCellEnergy

            nextCells[index].couplingState =

                couplingState

            calculatedLatticeEnergy +=

                totalCellEnergy

            strainSum +=

                strain

            twistSum +=

                abs(newTwist)

            amplitudeSum +=

                newAmplitude

            coherentSum +=

                cos(

                    phase -

                    phase

                )

        }

        cells = nextCells

        latticeEnergy =

            calculatedLatticeEnergy

        let count =

            Double(

                max(

                    cells.count,

                    1

                )

            )

        averageStrain =

            strainSum / count

        averageTwist =

            twistSum / count

        collectiveAmplitude =

            amplitudeSum / count

        // ----------------------------------------------------

        // Determine coherence from actual phase relationships.

        // ----------------------------------------------------

        calculateCollectiveCoherence()

        latticeExcited =

            latticeEnergy > 0.000001

    }

    // ========================================================

    // MARK: Collective Coherence

    // ========================================================

    private func calculateCollectiveCoherence() {

        guard !cells.isEmpty else {

            collectiveCoherence = 0

            return

        }

        var real = 0.0

        var imaginary = 0.0

        var totalWeight = 0.0

        for cell in cells {

            let weight =

                cell.localEnergy +

                cell.amplitude *

                cell.amplitude

            guard weight > 0.000001 else {

                continue

            }

            real +=

                weight *

                cos(cell.phase)

            imaginary +=

                weight *

                sin(cell.phase)

            totalWeight +=

                weight

        }

        guard totalWeight > 0 else {

            collectiveCoherence = 0

            return

        }

        collectiveCoherence =

            min(

                1.0,

                sqrt(

                    real * real +

                    imaginary * imaginary

                ) /

                totalWeight

            )

    }

    // ========================================================

    // ========================================================
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

            guard weight > 0.000001 else {

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

        // ----------------------------------------------------

        // Resonant mode energy is the energy associated with

        // the coherent, oscillating portion of the lattice.

        // ----------------------------------------------------

        var weightedEnergy = 0.0

        var totalEnergyWeight = 0.0

        var weightedAmplitude = 0.0

        var phaseReal = 0.0

        var phaseImaginary = 0.0

        var phaseWeight = 0.0

        for cell in cells {

            let oscillationEnergy =

                0.5 *

                cell.modeVelocity *

                cell.modeVelocity +

                0.5 *

                QRTLConstants.restoringForce *

                cell.modeCoordinate *

                cell.modeCoordinate

            guard oscillationEnergy > 0 else {

                continue

            }

            let weight =

                oscillationEnergy

            weightedEnergy +=

                oscillationEnergy

            totalEnergyWeight +=

                weight

            weightedAmplitude +=

                abs(

                    cell.modeCoordinate

                ) *

                weight

            phaseReal +=

                weight *

                cos(cell.phase)

            phaseImaginary +=

                weight *

                sin(cell.phase)

            phaseWeight +=

                weight

        }

        resonantModeEnergy =

            max(

                0,

                weightedEnergy

            )

        let modeAmplitude: Double

        if totalEnergyWeight > 0 {

            modeAmplitude =

                weightedAmplitude /

                totalEnergyWeight

        } else {

            modeAmplitude = 0

        }

        let modeCoherence: Double

        if phaseWeight > 0 {

            modeCoherence =

                min(

                    1.0,

                    sqrt(

                        phaseReal *

                        phaseReal +

                        phaseImaginary *

                        phaseImaginary

                    ) /

                    phaseWeight

                )

        } else {

            modeCoherence = 0

        }

        resonantMassGeV =

            massFromFrequency(

                resonantFrequencyHz

            )

        massDistanceFromTarget =

            abs(

                QRTLConstants.targetHiggsMassGeV -

                resonantMassGeV

            )

        higgsMode.frequencyHz =

            resonantFrequencyHz

        higgsMode.massGeV =

            resonantMassGeV

        higgsMode.energy =

            resonantModeEnergy

        higgsMode.amplitude =

            modeAmplitude

        higgsMode.coherence =

            modeCoherence

        higgsMode.shellEnergy =

            energyState.shellEnergy

        higgsMode.shellInstability =

            energyState.shellInstability

        // ----------------------------------------------------

        // Candidate activation is based on simulated behavior,

        // not on simply assigning 125 GeV.

        // ----------------------------------------------------

        let sufficientEnergy =

            resonantModeEnergy >

            0.000001

        let sufficientCoherence =

            modeCoherence >

            0.50

        let measuredFrequency =

            resonantFrequencyHz >

            0

        let shellWasDestabilized =

            formationThresholdEnergy >

            energyState.equilibriumShellEnergy

        higgsMode.active =

            collisionOccurred &&

            sufficientEnergy &&

            sufficientCoherence &&

            measuredFrequency &&

            shellWasDestabilized

        if higgsMode.active {

            higgsNode.isHidden = false

            let visualScale =

                Float(

                    max(

                        0.05,

                        min(

                            2.5,

                            modeAmplitude *

                            8.0

                        )

                    )

                )

            higgsNode.scale =

                SCNVector3(

                    visualScale,

                    visualScale,

                    visualScale

                )

            let pulse =

                0.85 +

                0.15 *

                sin(

                    simulationTime *

                    8.0

                )

            higgsNode.opacity =

                CGFloat(

                    max(

                        0.15,

                        min(

                            1.0,

                            modeCoherence *

                            pulse

                        )

                    )

                )

        } else {

            higgsNode.isHidden = true

        }

        // ----------------------------------------------------

        // Decay / return toward equilibrium

        // ----------------------------------------------------

        if !energyState.isUnstable &&

            higgsMode.active {

            higgsMode.decayProgress =

                min(

                    1.0,

                    higgsMode.decayProgress +

                    dt * 0.15

                )

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



extension QRTLConstants {

    // Physical constants
    static let protonMassKg = 1.67262192369e-27

    // Proton rest energy
    static let protonRestEnergyGeV = 0.93827208816

    // LHC Run 3 beam energy
    // 6.8 TeV per proton
    static let lhcProtonBeamEnergyTeV = 6.8

    static let lhcProtonBeamEnergyGeV =
        lhcProtonBeamEnergyTeV * 1_000.0

    // --------------------------------------------------------
    // Lorentz factor
    //
    // gamma = E / (m c²)
    // --------------------------------------------------------

    static let lhcLorentzFactor: Double = {

        lhcProtonBeamEnergyGeV /
        protonRestEnergyGeV
    }()

    // --------------------------------------------------------
    // Proton velocity
    //
    // v = c sqrt(1 - 1/gamma²)
    // --------------------------------------------------------

    static let lhcProtonSpeed: Double = {

        let gamma = lhcLorentzFactor

        guard gamma > 1.0 else {
            return 0.0
        }

        return speedOfLight *
            sqrt(
                1.0 -
                1.0 / (gamma * gamma)
            )
    }()

    // --------------------------------------------------------
    // Kinetic energy of ONE proton
    //
    // KE = (gamma - 1) m c²
    // --------------------------------------------------------

    static let singleProtonKineticEnergyGeV: Double = {

        (lhcLorentzFactor - 1.0) *
        protonRestEnergyGeV
    }()

    // --------------------------------------------------------
    // Kinetic energy of BOTH protons
    // --------------------------------------------------------

    static let twoProtonKineticEnergyGeV: Double = {

        2.0 *
        singleProtonKineticEnergyGeV
    }()

    // --------------------------------------------------------
    // Total proton-proton center-of-mass energy
    //
    // 6.8 TeV + 6.8 TeV = 13.6 TeV
    // --------------------------------------------------------

    static let protonProtonCollisionEnergyGeV: Double = {

        2.0 *
        lhcProtonBeamEnergyGeV
    }()

    // --------------------------------------------------------
    // GeV → joules
    // --------------------------------------------------------

    static let joulesPerGeV =
        1.602176634e-10

    // --------------------------------------------------------
    // TWO-PROTON KINETIC ENERGY IN JOULES
    // --------------------------------------------------------

    static let twoProtonKineticEnergyJ: Double = {

        twoProtonKineticEnergyGeV *
        joulesPerGeV
    }()

    // --------------------------------------------------------
    // TOTAL 13.6 TeV COLLISION ENERGY IN JOULES
    // --------------------------------------------------------

    static let protonProtonCollisionEnergyJ: Double = {

        protonProtonCollisionEnergyGeV *
        joulesPerGeV
    }()
}

