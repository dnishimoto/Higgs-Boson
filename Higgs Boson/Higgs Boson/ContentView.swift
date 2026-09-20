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
        // Formation threshold is the energy available at the
        // point where the equilibrium shell is destabilized.
        //
        // It is deliberately kept separate from the energy
        // later measured in the resonant mode.
        // ----------------------------------------------------

        formationThresholdEnergy =
            energyState.equilibriumShellEnergy +
            QRTLConstants.collisionEnergy

        energyState.kineticEnergy = 0

        energyState.shellEnergy =
            formationThresholdEnergy

        energyState.deformation = 1.0

        energyState.shellInstability = 1.0

        energyState.isUnstable = true

        // ----------------------------------------------------
        // Collision transfers energy into the lattice.
        // Crucially, this now supplies BOTH displacement AND
        // velocity.
        //
        // The velocity is what turns a static deformation into
        // a genuine oscillation.
        // ----------------------------------------------------

        exciteLatticeFromCollision()

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

    // ========================================================
    // MARK: Collision -> Lattice Oscillation
    // ========================================================

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

    // ========================================================
    // MARK: Lattice Dynamics
    // ========================================================

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

        // ----------------------------------------------------
        // Synchronous CA update
        //
        // Every cell reads the previous state and writes into
        // nextCells.
        // ----------------------------------------------------

        for index in cells.indices {

            let cell =
                cells[index]

            // ------------------------------------------------
            // Neighbor displacement coupling
            // ------------------------------------------------

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
