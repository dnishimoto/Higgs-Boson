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

        VStack(spacing: 0) {

            QRTLSceneView(simulation: simulation)
                .frame(maxWidth: .infinity)
                .frame(height: 430)

            ScrollView {

                VStack(spacing: 8) {

                    collisionCard
                    qrtlCard
                    latticeCard
                    energyCard
                    higgsCard

                    Text(
                        "QRTL model: proposed/unvalidated. " +
                        "The Higgs-like mode is a simulation candidate, " +
                        "not a claim of Standard Model Higgs production."
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                }
                .padding(8)
            }
            .frame(maxHeight: 410)

            HStack(spacing: 12) {

                Button {
                    simulation.isPaused.toggle()
                } label: {

                    Label(
                        simulation.isPaused
                        ? "Resume"
                        : "Pause",
                        systemImage:
                            simulation.isPaused
                            ? "play.fill"
                            : "pause.fill"
                    )
                }
                .buttonStyle(.borderedProminent)

                Button {
                    simulation.reset()
                } label: {

                    Label(
                        "Reset",
                        systemImage:
                            "arrow.counterclockwise"
                    )
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.04))
    }

    // ========================================================
    // MARK: - COLLISION CARD
    // ========================================================

    private var collisionCard: some View {

        monitorCard("COLLISION") {

            HStack {

                metric(
                    "Stage",
                    simulation.stage
                )

                Spacer()

                metric(
                    "Time",
                    String(
                        format: "%.3f",
                        simulation.time
                    )
                )
            }

            Divider()

            HStack(spacing: 14) {

                protonIndicator(
                    title: "P1",
                    color: .cyan,
                    state:
                        simulation.proton1.collided
                        ? "COLLIDED"
                        : "APPROACHING"
                )

                protonIndicator(
                    title: "P2",
                    color: .red,
                    state:
                        simulation.proton2.collided
                        ? "COLLIDED"
                        : "APPROACHING"
                )

                Spacer()

                metric(
                    "Distance",
                    String(
                        format: "%.3f",
                        simulation.protonDistance
                    )
                )
            }
        }
    }

    // ========================================================
    // MARK: - QRTL CARD
    // ========================================================

    private var qrtlCard: some View {

        monitorCard("QRTL SHELL") {

            HStack {

                metric(
                    "Shell",
                    String(
                        format: "%.3f",
                        simulation.energyState.shellEnergy
                    )
                )

                Spacer()

                metric(
                    "Equilibrium",
                    String(
                        format: "%.3f",
                        simulation.energyState
                            .equilibriumShellEnergy
                    )
                )
            }

            Divider()

            HStack {

                compactProgress(
                    "Instability",
                    min(
                        simulation.shellInstability,
                        1
                    )
                )

                compactProgress(
                    "Return",
                    min(
                        simulation.returnToStability,
                        1
                    )
                )
            }

            Text(
                simulation.isStableShell
                ? "STABLE ENERGY SHELL"
                : "ENERGY SHELL RETURNING"
            )
            .font(.caption.bold())
            .foregroundStyle(
                simulation.isStableShell
                ? .green
                : .orange
            )
        }
    }

    // ========================================================
    // MARK: - LATTICE CARD
    // ========================================================

    private var latticeCard: some View {

        monitorCard("LATTICE") {

            HStack {

                metric(
                    "Localized",
                    String(
                        format: "%.4f",
                        simulation.localizedEnergy
                    )
                )

                Spacer()

                metric(
                    "Field",
                    String(
                        format: "%.4f",
                        simulation.qrtlField
                    )
                )

                Spacer()

                metric(
                    "Current",
                    String(
                        format: "%.4f",
                        simulation.qrtlCurrent
                    )
                )
            }

            Divider()

            HStack {

                compactProgress(
                    "Coherence",
                    simulation.phaseCoherence
                )

                compactProgress(
                    "Strain",
                    min(
                        simulation.averageStrain,
                        1
                    )
                )

                compactProgress(
                    "Twist",
                    min(
                        simulation.averageTwist,
                        1
                    )
                )
            }

            Text(
                "Collective state: " +
                simulation.collectiveState
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // ========================================================
    // MARK: - ENERGY CARD
    // ========================================================

    private var energyCard: some View {

        monitorCard("ENERGY") {

            HStack {

                metric(
                    "Initial",
                    String(
                        format: "%.3f",
                        simulation.energyState.initialTotalEnergy
                    )
                )

                Spacer()

                metric(
                    "Current",
                    String(
                        format: "%.3f",
                        simulation.energyState.totalEnergy
                    )
                )

                Spacer()

                metric(
                    "Error",
                    String(
                        format: "%.5f%%",
                        simulation.energyState
                            .conservationError * 100
                    )
                )
            }

            Divider()

            HStack {

                metric(
                    "Kinetic",
                    String(
                        format: "%.3f",
                        simulation.energyState.kineticEnergy
                    )
                )

                Spacer()

                metric(
                    "Shell",
                    String(
                        format: "%.3f",
                        simulation.energyState.shellExcessEnergy
                    )
                )

                Spacer()

                metric(
                    "Lattice",
                    String(
                        format: "%.3f",
                        simulation.energyState.latticeEnergy
                    )
                )

                Spacer()

                metric(
                    "Mode",
                    String(
                        format: "%.3f",
                        simulation.energyState.modeEnergy
                    )
                )
            }

            Text(
                "Conserved fraction: " +
                String(
                    format: "%.3f%%",
                    simulation.energyState
                        .conservedEnergyFraction * 100
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // ========================================================
    // MARK: - HIGGS CARD
    // ========================================================

    private var higgsCard: some View {

        monitorCard("HIGGS-LIKE MODE") {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        simulation.higgsMode.active
                        ? "FORMING"
                        : "NOT ACTIVE"
                    )
                    .font(.headline)
                    .foregroundStyle(
                        simulation.higgsMode.active
                        ? .purple
                        : .secondary
                    )

                    Text(
                        simulation.higgsMode.active
                        ? "Collective mode detected"
                        : simulation.formationStatus
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                metric(
                    "Mode Energy",
                    String(
                        format: "%.5f",
                        simulation.higgsMode.energy
                    )
                )
            }

            Divider()

            HStack {
                metric(
                    "Amplitude",
                    String(format: "%.3f", simulation.higgsMode.amplitude)
                )

                Spacer()

                metric(
                    "Coherence",
                    String(format: "%.3f", simulation.higgsMode.coherence)
                )

                Spacer()

                metric(
                    "Resonant Mass",
                    String(format: "%.3f GeV", simulation.higgsMode.massGeV)
                )

                Spacer()

                metric(
                    "Target",
                    "125.000 GeV"
                )
            }

            let massDifference = abs(
                simulation.higgsMode.massGeV - 125.0
            )

            Text(
                "Distance from 125 GeV: " +
                String(format: "%.3f GeV", massDifference)
            )
            .font(.caption)
            .foregroundStyle(
                massDifference < 1.0 ? .green : .secondary
            )
            Text(
                "125 GeV is a comparison target; " +
                "the simulation mode energy determines " +
                "the displayed comparison."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    // ========================================================
    // MARK: - CARD HELPERS
    // ========================================================

    private func monitorCard<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 7
        ) {

            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            content()
        }
        .padding(10)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: 10
            )
            .fill(
                Color(.secondarySystemBackground)
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 10
            )
            .stroke(
                Color.primary.opacity(0.08),
                lineWidth: 1
            )
        )
    }

    private func metric(
        _ title: String,
        _ value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 2
        ) {

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(
                    .system(
                        size: 12,
                        weight: .semibold,
                        design: .monospaced
                    )
                )
                .lineLimit(1)
        }
    }

    private func protonIndicator(
        title: String,
        color: Color,
        state: String
    ) -> some View {

        HStack(spacing: 5) {

            Circle()
                .fill(color)
                .frame(
                    width: 10,
                    height: 10
                )

            VStack(
                alignment: .leading,
                spacing: 1
            ) {

                Text(title)
                    .font(.caption.bold())

                Text(state)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func compactProgress(
        _ title: String,
        _ value: Double
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 2
        ) {

            HStack {

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(
                    String(
                        format: "%.2f",
                        value
                    )
                )
                .font(
                    .caption2.monospaced()
                )
            }

            ProgressView(
                value:
                    min(
                        max(value, 0),
                        1
                    )
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// ============================================================
// MARK: - ENERGY STATE
// ============================================================

struct QRTLEnergyState {

    let equilibriumShellEnergy: Double = 2.0

    var shellEnergy: Double = 2.0

    var kineticEnergy: Double = 8.0

    var latticeEnergy: Double = 0.0

    var fieldEnergy: Double = 0.0

    var modeEnergy: Double = 0.0

    var initialTotalEnergy: Double = 10.0

    var shellEnergyDeviation: Double {

        shellEnergy -
        equilibriumShellEnergy
    }

    var shellInstability: Double {

        abs(
            shellEnergyDeviation
        ) /
        max(
            abs(
                equilibriumShellEnergy
            ),
            1e-12
        )
    }

    var returnToStability: Double {

        1.0 -
        exp(
            -min(
                max(
                    shellInstability,
                    0
                ),
                20
            )
        )
    }

    var isStableShell: Bool {

        shellInstability < 0.05
    }

    var shellExcessEnergy: Double {

        max(
            0,
            shellEnergy -
            equilibriumShellEnergy
        )
    }

    var totalEnergy: Double {

        kineticEnergy +
        shellExcessEnergy +
        latticeEnergy +
        fieldEnergy +
        modeEnergy
    }

    var conservationError: Double {

        abs(
            totalEnergy -
            initialTotalEnergy
        ) /
        max(
            abs(
                initialTotalEnergy
            ),
            1e-12
        )
    }

    var conservedEnergyFraction: Double {

        max(
            0,
            1 -
            conservationError
        )
    }
}

// ============================================================
// MARK: - QRTL CELL
// ============================================================

struct QRTLCell {

    var position: SIMD3<Float>

    var displacement: SIMD3<Float>

    var velocity: SIMD3<Float>

    var twist: Double

    var phase: Double

    var amplitude: Double

    var localEnergy: Double

    var localStrain: Double

    var couplingState: Double
}

// ============================================================
// MARK: - PROTON
// ============================================================

struct QRTLProton {

    var position: SIMD3<Float>

    var velocity: SIMD3<Float>

    var energy: Double

    var shellEnergy: Double

    var shellInstability: Double

    var excitation: Double

    var collided: Bool

    var colorIndex: Int
}

// ============================================================
// MARK: - HIGGS-LIKE MODE
// ============================================================

struct HiggsLikeMode {

    var active: Bool = false

    var age: Double = 0

    var energy: Double = 0

    var massGeV: Double = 0

    var amplitude: Double = 0

    var phase: Double = 0

    var coherence: Double = 0

    var shellEnergy: Double = 0

    var shellInstability: Double = 0

    var decayProgress: Double = 0
}

// ============================================================
// MARK: - SIMULATION
// ============================================================

final class QRTLSimulation: ObservableObject {

    @Published var cells: [QRTLCell] = []

    @Published var proton1: QRTLProton

    @Published var proton2: QRTLProton

    @Published var energyState =
        QRTLEnergyState()

    @Published var higgsMode =
        HiggsLikeMode()

    @Published var time: Double = 0

    @Published var stage =
        "Protons Approaching"

    @Published var isPaused = false

    @Published var qrtlField: Double = 0

    @Published var qrtlCurrent: Double = 0

    @Published var borlagrinoFlow: Double = 0

    @Published var localizedEnergy: Double = 0

    @Published var phaseCoherence: Double = 0

    @Published var averageStrain: Double = 0

    @Published var averageTwist: Double = 0

    // --------------------------------------------------------
    // COMPUTED STATE
    // --------------------------------------------------------

    var shellInstability: Double {

        energyState.shellInstability
    }

    var returnToStability: Double {

        energyState.returnToStability
    }

    var isStableShell: Bool {

        energyState.isStableShell
    }

    var totalEnergy: Double {

        energyState.totalEnergy
    }

    var conservationError: Double {

        energyState.conservationError
    }

    var conservedEnergyFraction: Double {

        energyState.conservedEnergyFraction
    }

    var protonDistance: Double {

        Double(
            simd_distance(
                proton1.position,
                proton2.position
            )
        )
    }

    var collectiveState: String {

        if phaseCoherence > 0.90 {
            return "Highly coherent"
        }

        if phaseCoherence > 0.60 {
            return "Collective"
        }

        if phaseCoherence > 0.30 {
            return "Developing"
        }

        return "Localized"
    }

    var formationStatus: String {

        if !proton1.collided {
            return "Awaiting collision"
        }

        if phaseCoherence < 0.30 {
            return "Low coherence"
        }

        if localizedEnergy < 0.05 {
            return "Insufficient localized energy"
        }

        if higgsMode.active {
            return "Collective mode active"
        }

        return "Mode conditions developing"
    }

    // --------------------------------------------------------
    // SIMULATION PARAMETERS
    // --------------------------------------------------------

    private let gridSize = 17

    // Physics remains at 0.002 seconds.
    private let timeStep = 0.002

    // Four physics integrations per display update.
    private let physicsStepsPerFrame = 4

    // Faster proton approach.
    private let protonApproachSpeed: Float = 4.0

    private let collisionDistance: Float = 0.55

    private let restoringForce = 0.20

    private let damping = 0.008

    private let twistCoupling = 0.08

    private let phaseCoupling = 0.12

    private let strainCoupling = 0.06

    private let qrtlCoupling = 0.10

    private let modeThreshold = 0.002

    private let comparisonMassGeV = 125.0

    // --------------------------------------------------------
    // SIX NEIGHBOR OFFSETS
    // --------------------------------------------------------

    private let latticeNeighborOffsets:
        [(Int, Int, Int)] = [

            (1, 0, 0),
            (-1, 0, 0),

            (0, 1, 0),
            (0, -1, 0),

            (0, 0, 1),
            (0, 0, -1)
        ]

    // --------------------------------------------------------
    // TIMER
    // --------------------------------------------------------

    private var timer: Timer?

    private var hasCollided = false

    // --------------------------------------------------------
    // INIT
    // --------------------------------------------------------

    init() {

        proton1 = QRTLProton(
            position:
                SIMD3<Float>(
                    -6,
                    0,
                    0
                ),
            velocity:
                SIMD3<Float>(
                    protonApproachSpeed,
                    0,
                    0
                ),
            energy: 4.0,
            shellEnergy: 1.0,
            shellInstability: 0,
            excitation: 0,
            collided: false,
            colorIndex: 0
        )

        proton2 = QRTLProton(
            position:
                SIMD3<Float>(
                    6,
                    0,
                    0
                ),
            velocity:
                SIMD3<Float>(
                    -protonApproachSpeed,
                    0,
                    0
                ),
            energy: 4.0,
            shellEnergy: 1.0,
            shellInstability: 0,
            excitation: 0,
            collided: false,
            colorIndex: 1
        )

        createLattice()

        recordInitialEnergy()

        start()
    }

    deinit {

        timer?.invalidate()
    }

    // ========================================================
    // MARK: - LATTICE INDEX
    // ========================================================

    private func latticeIndex(
        x: Int,
        y: Int,
        z: Int
    ) -> Int {

        z *
        gridSize *
        gridSize +
        y *
        gridSize +
        x
    }

    // ========================================================
    // MARK: - LATTICE CREATION
    // ========================================================

    private func createLattice() {

        cells.removeAll(
            keepingCapacity: true
        )

        let half =
            Float(
                gridSize - 1
            ) /
            2.0

        for z in 0..<gridSize {

            for y in 0..<gridSize {

                for x in 0..<gridSize {

                    let position =
                        SIMD3<Float>(
                            Float(x) - half,
                            Float(y) - half,
                            Float(z) - half
                        )

                    cells.append(
                        QRTLCell(
                            position: position,
                            displacement: .zero,
                            velocity: .zero,
                            twist: 0,
                            phase: 0,
                            amplitude: 0,
                            localEnergy: 0,
                            localStrain: 0,
                            couplingState: 0
                        )
                    )
                }
            }
        }
    }

    // ========================================================
    // MARK: - INITIAL ENERGY
    // ========================================================

    private func recordInitialEnergy() {

        energyState.kineticEnergy =
            proton1.energy +
            proton2.energy

        energyState.shellEnergy =
            energyState.equilibriumShellEnergy

        energyState.latticeEnergy = 0

        energyState.fieldEnergy = 0

        energyState.modeEnergy = 0

        energyState.initialTotalEnergy =
            energyState.totalEnergy
    }

    // ========================================================
    // MARK: - DISPLAY TIMER
    // ========================================================

    private func start() {

        timer?.invalidate()

        // ----------------------------------------------------
        // 60 Hz display timer.
        //
        // The physics still advances using the smaller
        // 0.002 second timestep.
        // ----------------------------------------------------

        timer =
            Timer.scheduledTimer(
                withTimeInterval:
                    1.0 / 60.0,
                repeats: true
            ) { [weak self] _ in

                guard let self else {
                    return
                }

                guard !self.isPaused else {
                    return
                }

                self.advancePhysics()
            }
    }

    // ========================================================
    // MARK: - PHYSICS ADVANCE
    // ========================================================

    private func advancePhysics() {

        for _ in 0..<physicsStepsPerFrame {

            stepPhysics()
        }
    }

    // ========================================================
    // MARK: - PHYSICS STEP
    // ========================================================

    private func stepPhysics() {

        time += timeStep

        if !hasCollided {

            stage =
                "Protons Approaching"

            updateProtonMotion()

            detectCollision()

            return
        }

        updateCollisionDynamics()

        updateLattice()

        updateQRTLField()

        updateQRTLCurrent()

        updateBorlagrinoFlow()

        updateCollectiveState()

        updateHiggsLikeMode()

        updateEnergyConservation()
    }

    // ========================================================
    // MARK: - PROTON MOTION
    // ========================================================

    private func updateProtonMotion() {

        proton1.position +=
            proton1.velocity *
            Float(timeStep)

        proton2.position +=
            proton2.velocity *
            Float(timeStep)
    }

    // ========================================================
    // MARK: - COLLISION
    // ========================================================

    private func detectCollision() {

        if protonDistance <=
            Double(collisionDistance) {

            performCollision()
        }
    }

    private func performCollision() {

        hasCollided = true

        proton1.collided = true
        proton2.collided = true

        let collisionPosition =
            (
                proton1.position +
                proton2.position
            ) *
            0.5

        proton1.position =
            collisionPosition

        proton2.position =
            collisionPosition

        proton1.velocity =
            .zero

        proton2.velocity =
            .zero

        let incomingEnergy =
            proton1.energy +
            proton2.energy

        energyState.kineticEnergy = 0

        // Collision kinetic energy becomes shell excess.
        energyState.shellEnergy =
            energyState.equilibriumShellEnergy +
            incomingEnergy

        proton1.shellEnergy =
            energyState.shellEnergy * 0.5

        proton2.shellEnergy =
            energyState.shellEnergy * 0.5

        updateProtonShellState()

        stage =
            "ENERGY SHELL UNSTABLE"
    }

    // ========================================================
    // MARK: - SHELL DYNAMICS
    // ========================================================

    private func updateCollisionDynamics() {

        let excess =
            energyState.shellExcessEnergy

        guard excess > 0 else {

            energyState.shellEnergy =
                energyState.equilibriumShellEnergy

            updateProtonShellState()

            return
        }

        let normalizedInstability =
            min(
                excess /
                max(
                    energyState.equilibriumShellEnergy,
                    1e-12
                ),
                20
            )

        let transferRate =
            min(
                1.0,
                qrtlCoupling *
                (1.0 + normalizedInstability) *
                timeStep *
                25.0
            )

        let transfer =
            min(
                excess,
                excess *
                transferRate
            )

        energyState.shellEnergy -=
            transfer

        depositEnergyIntoLattice(
            transfer
        )

        updateProtonShellState()

        if energyState.shellInstability > 0.05 {

            stage =
                "Shell Returning Toward Stability"

        } else {

            stage =
                "QRTL Equilibrium Recovery"
        }
    }

    private func updateProtonShellState() {

        let instability =
            energyState.shellInstability

        proton1.shellEnergy =
            energyState.shellEnergy * 0.5

        proton2.shellEnergy =
            energyState.shellEnergy * 0.5

        proton1.shellInstability =
            instability

        proton2.shellInstability =
            instability

        proton1.excitation =
            min(
                1,
                instability
            )

        proton2.excitation =
            min(
                1,
                instability
            )
    }

    // ========================================================
    // MARK: - ENERGY DEPOSITION
    // ========================================================

    private func depositEnergyIntoLattice(
        _ energy: Double
    ) {

        guard energy > 0 else {
            return
        }

        let radius = 3.0

        var weights =
            [Double](
                repeating: 0,
                count: cells.count
            )

        var weightSum = 0.0

        for index in cells.indices {

            let distance =
                Double(
                    simd_length(
                        cells[index].position
                    )
                )

            if distance <= radius {

                let normalized =
                    max(
                        0,
                        1 -
                        distance / radius
                    )

                let weight =
                    normalized *
                    normalized

                weights[index] =
                    weight

                weightSum +=
                    weight
            }
        }

        guard weightSum > 0 else {
            return
        }

        for index in cells.indices {

            let share =
                energy *
                weights[index] /
                weightSum

            guard share > 0 else {
                continue
            }

            cells[index].localEnergy +=
                share

            cells[index].amplitude +=
                sqrt(
                    max(
                        share,
                        0
                    )
                ) *
                0.20

            cells[index].couplingState =
                min(
                    1,
                    cells[index].couplingState +
                    share *
                    0.05
                )

            cells[index].displacement +=
                SIMD3<Float>(
                    Float(
                        sqrt(
                            max(
                                share,
                                0
                            )
                        ) *
                        0.05
                    ),
                    0,
                    0
                )

            cells[index].localStrain =
                Double(
                    simd_length(
                        cells[index].displacement
                    )
                )
        }
    }

    // ========================================================
    // MARK: - OPTIMIZED LATTICE
    // ========================================================

    private func updateLattice() {

        guard !cells.isEmpty else {
            return
        }

        var updated =
            cells

        // ----------------------------------------------------
        // IMPORTANT:
        //
        // This uses only the six adjacent cells instead of
        // comparing every cell against all 4,913 cells.
        // ----------------------------------------------------

        for index in cells.indices {

            let local =
                cells[index]

            let z =
                index /
                (gridSize * gridSize)

            let remainder =
                index %
                (gridSize * gridSize)

            let y =
                remainder /
                gridSize

            let x =
                remainder %
                gridSize

            var neighborEnergy = 0.0

            var neighborPhaseX = 0.0

            var neighborPhaseY = 0.0

            var neighborTwist = 0.0

            var neighborCount = 0.0

            for offset in
                latticeNeighborOffsets {

                let nx =
                    x +
                    offset.0

                let ny =
                    y +
                    offset.1

                let nz =
                    z +
                    offset.2

                guard
                    nx >= 0,
                    nx < gridSize,
                    ny >= 0,
                    ny < gridSize,
                    nz >= 0,
                    nz < gridSize
                else {
                    continue
                }

                let neighborIndex =
                    latticeIndex(
                        x: nx,
                        y: ny,
                        z: nz
                    )

                let neighbor =
                    cells[neighborIndex]

                neighborEnergy +=
                    neighbor.localEnergy

                neighborPhaseX +=
                    cos(
                        neighbor.phase
                    )

                neighborPhaseY +=
                    sin(
                        neighbor.phase
                    )

                neighborTwist +=
                    neighbor.twist

                neighborCount += 1
            }

            guard neighborCount > 0 else {
                continue
            }

            let averageNeighborEnergy =
                neighborEnergy /
                neighborCount

            let averageNeighborPhase =
                atan2(
                    neighborPhaseY /
                    neighborCount,
                    neighborPhaseX /
                    neighborCount
                )

            let averageNeighborTwist =
                neighborTwist /
                neighborCount

            // ------------------------------------------------
            // Local energy exchange.
            // ------------------------------------------------

            let energyDifference =
                averageNeighborEnergy -
                local.localEnergy

            let exchange =
                energyDifference *
                0.08

            updated[index].localEnergy =
                max(
                    0,
                    local.localEnergy +
                    exchange *
                    timeStep *
                    20
                )

            // ------------------------------------------------
            // Restoring response.
            // ------------------------------------------------

            let restoring =
                -local.displacement *
                Float(
                    restoringForce
                )

            let neighborResponse =
                SIMD3<Float>(
                    Float(
                        energyDifference *
                        strainCoupling
                    ),
                    Float(
                        energyDifference *
                        strainCoupling
                    ),
                    Float(
                        energyDifference *
                        strainCoupling
                    )
                )

            let acceleration =
                restoring +
                neighborResponse -
                local.velocity *
                Float(damping)

            updated[index].velocity +=
                acceleration *
                Float(timeStep)

            updated[index].displacement +=
                updated[index].velocity *
                Float(timeStep)

            updated[index].localStrain =
                Double(
                    simd_length(
                        updated[index].displacement
                    )
                )

            // ------------------------------------------------
            // Twist.
            // ------------------------------------------------

            let twistDelta =
                averageNeighborTwist -
                local.twist

            updated[index].twist +=
                twistDelta *
                twistCoupling *
                timeStep

            // ------------------------------------------------
            // Phase.
            // ------------------------------------------------

            var phaseDelta =
                averageNeighborPhase -
                local.phase

            phaseDelta =
                wrapPhase(
                    phaseDelta
                )

            updated[index].phase +=
                phaseDelta *
                phaseCoupling *
                timeStep

            updated[index].phase =
                wrapPhase(
                    updated[index].phase
                )

            // ------------------------------------------------
            // Visualization amplitude.
            // ------------------------------------------------

            updated[index].amplitude =
                sqrt(
                    max(
                        updated[index].localEnergy,
                        0
                    )
                )

            updated[index].couplingState =
                min(
                    1,
                    max(
                        0,
                        updated[index].couplingState +
                        abs(exchange) *
                        0.01
                    )
                )
        }

        cells =
            updated
    }

    // ========================================================
    // MARK: - FIELD
    // ========================================================

    private func updateQRTLField() {

        let total =
            cells.reduce(
                0
            ) {
                $0 +
                $1.localEnergy
            }

        localizedEnergy =
            max(
                0,
                total
            )

        qrtlField =
            cells.isEmpty
            ? 0
            : localizedEnergy /
              Double(
                  cells.count
              )
    }

    // ========================================================
    // MARK: - CURRENT
    // ========================================================

    private func updateQRTLCurrent() {

        guard !cells.isEmpty else {

            qrtlCurrent = 0

            return
        }

        var sum = 0.0

        for cell in cells {

            let speed =
                Double(
                    simd_length(
                        cell.velocity
                    )
                )

            sum +=
                cell.localEnergy *
                speed *
                (
                    1 +
                    abs(
                        cell.twist
                    )
                )
        }

        qrtlCurrent =
            sum /
            Double(
                cells.count
            )
    }

    // ========================================================
    // MARK: - FLOW
    // ========================================================

    private func updateBorlagrinoFlow() {

        guard !cells.isEmpty else {

            borlagrinoFlow = 0

            return
        }

        var total = 0.0

        for cell in cells {

            total +=
                abs(
                    cell.twist
                ) *
                cell.localEnergy *
                (
                    1 +
                    abs(
                        cell.localStrain
                    )
                )
        }

        borlagrinoFlow =
            total /
            Double(
                cells.count
            )
    }

    // ========================================================
    // MARK: - COLLECTIVE STATE
    // ========================================================

    private func updateCollectiveState() {

        guard !cells.isEmpty else {

            phaseCoherence = 0
            averageStrain = 0
            averageTwist = 0

            return
        }

        var phaseX = 0.0

        var phaseY = 0.0

        var strain = 0.0

        var twist = 0.0

        for cell in cells {

            phaseX +=
                cos(
                    cell.phase
                )

            phaseY +=
                sin(
                    cell.phase
                )

            strain +=
                abs(
                    cell.localStrain
                )

            twist +=
                abs(
                    cell.twist
                )
        }

        let count =
            Double(
                cells.count
            )

        phaseCoherence =
            min(
                1,
                sqrt(
                    phaseX *
                    phaseX +
                    phaseY *
                    phaseY
                ) /
                count
            )

        averageStrain =
            strain /
            count

        averageTwist =
            twist /
            count
    }

    // ========================================================
    // MARK: - HIGGS-LIKE MODE
    // ========================================================

    private func updateHiggsLikeMode() {

        guard hasCollided else {
            return
        }

        let instability =
            shellInstability

        let coherence =
            phaseCoherence

        let localized =
            localizedEnergy

        let current =
            max(
                qrtlCurrent,
                0
            )

        let excitationDriver =
            localized *
            coherence *
            (1 + current)

        let formationStrength =
            instability *
            excitationDriver *
            qrtlCoupling

        // ----------------------------------------------------
        // Formation condition.
        // ----------------------------------------------------

        if !higgsMode.active {

            let thresholdSatisfied =
                instability > 0.10 &&
                coherence > 0.45 &&
                localized > 0.01 &&
                formationStrength >
                    modeThreshold

            if thresholdSatisfied {

                let available =
                    energyState.latticeEnergy

                let modeAllocation =
                    min(
                        available * 0.002,
                        formationStrength *
                        timeStep *
                        10
                    )

                if modeAllocation > 0 {

                    energyState.latticeEnergy -=
                        modeAllocation

                    energyState.modeEnergy +=
                        modeAllocation

                    higgsMode.active =
                        true

                    higgsMode.age =
                        0

                    higgsMode.energy =
                        modeAllocation

                    higgsMode.amplitude =
                        min(
                            1,
                            sqrt(
                                modeAllocation
                            )
                        )

                    higgsMode.coherence =
                        coherence

                    higgsMode.phase =
                        collectivePhase()

                    higgsMode.shellEnergy =
                        energyState.shellEnergy

                    higgsMode.shellInstability =
                        instability

                    higgsMode.massGeV =
                        simulatedMassComparison(
                            modeAllocation
                        )

                    stage =
                        "Higgs-like Mode Forming"
                }
            }

            return
        }

        // ----------------------------------------------------
        // Active mode.
        // ----------------------------------------------------

        higgsMode.age +=
            timeStep

        higgsMode.coherence =
            coherence

        higgsMode.phase =
            collectivePhase()

        higgsMode.shellEnergy =
            energyState.shellEnergy

        higgsMode.shellInstability =
            instability

        // ----------------------------------------------------
        // Lattice → mode.
        // ----------------------------------------------------

        let latticeAvailable =
            energyState.latticeEnergy

        let growth =
            min(
                latticeAvailable,
                formationStrength *
                timeStep *
                0.05
            )

        if growth > 0 {

            energyState.latticeEnergy -=
                growth

            energyState.modeEnergy +=
                growth

            higgsMode.energy +=
                growth
        }

        // ----------------------------------------------------
        // Mode → lattice during decay.
        // ----------------------------------------------------

        let decay =
            min(
                higgsMode.energy,
                higgsMode.energy *
                damping *
                timeStep *
                20
            )

        if decay > 0 {

            higgsMode.energy -=
                decay

            energyState.modeEnergy -=
                decay

            energyState.latticeEnergy +=
                decay

            higgsMode.decayProgress =
                min(
                    1,
                    higgsMode.decayProgress +
                    decay
                )
        }

        higgsMode.amplitude =
            min(
                1,
                sqrt(
                    max(
                        higgsMode.energy,
                        0
                    )
                )
            )

        higgsMode.massGeV =
            simulatedMassComparison(
                higgsMode.energy
            )

        if higgsMode.amplitude < 0.01 {

            higgsMode.active =
                false

            stage =
                "Collective Mode Decaying"
        }
    }

    // ========================================================
    // MARK: - PHASE
    // ========================================================

    private func collectivePhase() -> Double {

        guard !cells.isEmpty else {
            return 0
        }

        var x = 0.0

        var y = 0.0

        for cell in cells {

            x +=
                cos(
                    cell.phase
                )

            y +=
                sin(
                    cell.phase
                )
        }

        return atan2(
            y,
            x
        )
    }

    // ========================================================
    // MARK: - MASS COMPARISON
    // ========================================================

    private func simulatedMassComparison(
        _ energy: Double
    ) -> Double {

        guard energy > 0 else {
            return 0
        }

        return min(
            comparisonMassGeV,
            energy *
            comparisonMassGeV
        )
    }

    // ========================================================
    // MARK: - ENERGY ACCOUNTING
    // ========================================================

    private func updateEnergyConservation() {

        energyState.fieldEnergy =
            0

        energyState.latticeEnergy =
            max(
                0,
                cells.reduce(
                    0
                ) {
                    $0 +
                    $1.localEnergy
                }
            )

        energyState.modeEnergy =
            max(
                0,
                higgsMode.energy
            )
    }

    // ========================================================
    // MARK: - PHASE WRAP
    // ========================================================

    private func wrapPhase(
        _ phase: Double
    ) -> Double {

        var value =
            phase

        while value >
                Double.pi {

            value -=
                2 *
                Double.pi
        }

        while value <
                -Double.pi {

            value +=
                2 *
                Double.pi
        }

        return value
    }

    // ========================================================
    // MARK: - RESET
    // ========================================================

    func reset() {

        timer?.invalidate()

        hasCollided = false

        time = 0

        stage =
            "Protons Approaching"

        isPaused = false

        proton1 =
            QRTLProton(
                position:
                    SIMD3<Float>(
                        -6,
                        0,
                        0
                    ),
                velocity:
                    SIMD3<Float>(
                        protonApproachSpeed,
                        0,
                        0
                    ),
                energy: 4.0,
                shellEnergy: 1.0,
                shellInstability: 0,
                excitation: 0,
                collided: false,
                colorIndex: 0
            )

        proton2 =
            QRTLProton(
                position:
                    SIMD3<Float>(
                        6,
                        0,
                        0
                    ),
                velocity:
                    SIMD3<Float>(
                        -protonApproachSpeed,
                        0,
                        0
                    ),
                energy: 4.0,
                shellEnergy: 1.0,
                shellInstability: 0,
                excitation: 0,
                collided: false,
                colorIndex: 1
            )

        energyState =
            QRTLEnergyState()

        higgsMode =
            HiggsLikeMode()

        qrtlField = 0

        qrtlCurrent = 0

        borlagrinoFlow = 0

        localizedEnergy = 0

        phaseCoherence = 0

        averageStrain = 0

        averageTwist = 0

        createLattice()

        recordInitialEnergy()

        start()
    }
}

// ============================================================
// MARK: - SCENE VIEW
// ============================================================

struct QRTLSceneView:
    UIViewRepresentable {

    @ObservedObject var simulation:
        QRTLSimulation

    func makeCoordinator()
        -> Coordinator {

        Coordinator()
    }

    func makeUIView(
        context: Context
    ) -> SCNView {

        let view =
            SCNView()

        view.backgroundColor =
            UIColor.black

        view.allowsCameraControl =
            true

        view.autoenablesDefaultLighting =
            false

        let scene =
            SCNScene()

        view.scene =
            scene

        let cameraNode =
            SCNNode()

        cameraNode.camera =
            SCNCamera()

        cameraNode.camera?.fieldOfView =
            55

        cameraNode.position =
            SCNVector3(
                0,
                8,
                18
            )

        let cameraTarget =
            SCNNode()

        cameraTarget.position =
            SCNVector3(
                0,
                0,
                0
            )

        scene.rootNode.addChildNode(
            cameraTarget
        )

        let lookAt =
            SCNLookAtConstraint(
                target: cameraTarget
            )

        lookAt.isGimbalLockEnabled =
            true

        cameraNode.constraints =
            [lookAt]

        scene.rootNode.addChildNode(
            cameraNode
        )

        context.coordinator.cameraNode =
            cameraNode

        let lightNode =
            SCNNode()

        let light =
            SCNLight()

        light.type =
            .omni

        light.intensity =
            1400

        lightNode.light =
            light

        lightNode.position =
            SCNVector3(
                0,
                10,
                10
            )

        scene.rootNode.addChildNode(
            lightNode
        )

        let ambientNode =
            SCNNode()

        let ambient =
            SCNLight()

        ambient.type =
            .ambient

        ambient.intensity =
            250

        ambientNode.light =
            ambient

        scene.rootNode.addChildNode(
            ambientNode
        )

        // ----------------------------------------------------
        // Create the lattice visualization ONCE.
        // ----------------------------------------------------

        createLatticeNodes(
            scene: scene,
            simulation: simulation,
            coordinator:
                context.coordinator
        )

        return view
    }

    func updateUIView(
        _ view: SCNView,
        context: Context
    ) {

        guard let scene =
            view.scene
        else {
            return
        }

        updateLatticeNodes(
            simulation: simulation,
            coordinator:
                context.coordinator
        )

        updateProtonNode(
            context.coordinator.proton1Node,
            proton:
                simulation.proton1,
            color:
                .cyan
        )

        updateProtonNode(
            context.coordinator.proton2Node,
            proton:
                simulation.proton2,
            color:
                .red
        )

        updateHiggsNode(
            context.coordinator.higgsNode,
            mode:
                simulation.higgsMode
        )

        _ = scene
    }

    // ========================================================
    // MARK: - CREATE LATTICE NODES
    // ========================================================

    private func createLatticeNodes(
        scene: SCNScene,
        simulation: QRTLSimulation,
        coordinator: Coordinator
    ) {

        let container =
            SCNNode()

        container.name =
            "lattice"

        scene.rootNode.addChildNode(
            container
        )

        let spacing: Float =
            0.75

        for cell in simulation.cells {

            let sphere =
                SCNSphere(
                    radius: 0.035
                )

            let material =
                SCNMaterial()

            material.diffuse.contents =
                UIColor.blue

            sphere.firstMaterial =
                material

            let node =
                SCNNode(
                    geometry: sphere
                )

            node.position =
                SCNVector3(
                    cell.position.x *
                    spacing,
                    cell.position.y *
                    spacing,
                    cell.position.z *
                    spacing
                )

            container.addChildNode(
                node
            )

            coordinator.latticeNodes.append(
                node
            )
        }

        // ----------------------------------------------------
        // Proton nodes.
        // ----------------------------------------------------

        coordinator.proton1Node =
            createProtonNode(
                color:
                    .cyan
            )

        coordinator.proton2Node =
            createProtonNode(
                color:
                    .red
            )

        container.addChildNode(
            coordinator.proton1Node
        )

        container.addChildNode(
            coordinator.proton2Node
        )

        // ----------------------------------------------------
        // Higgs-like mode node.
        // ----------------------------------------------------

        coordinator.higgsNode =
            SCNNode()

        container.addChildNode(
            coordinator.higgsNode
        )
    }

    // ========================================================
    // MARK: - UPDATE LATTICE NODES
    // ========================================================

    private func updateLatticeNodes(
        simulation: QRTLSimulation,
        coordinator: Coordinator
    ) {

        guard
            coordinator.latticeNodes.count ==
                simulation.cells.count
        else {
            return
        }

        let maxEnergy =
            max(
                simulation.localizedEnergy,
                0.000001
            )

        let spacing: Float =
            0.75

        for index in simulation.cells.indices {

            let cell =
                simulation.cells[index]

            let node =
                coordinator.latticeNodes[index]

            let normalized =
                min(
                    max(
                        cell.localEnergy /
                        maxEnergy,
                        0
                    ),
                    1
                )

            let radius =
                CGFloat(
                    0.025 +
                    normalized *
                    0.12
                )

            if let sphere =
                node.geometry
                as? SCNSphere {

                sphere.radius =
                    radius

                if normalized > 0.65 {

                    sphere.firstMaterial?
                        .diffuse.contents =
                        UIColor.orange

                    sphere.firstMaterial?
                        .emission.contents =
                        UIColor.orange

                } else if normalized > 0.20 {

                    sphere.firstMaterial?
                        .diffuse.contents =
                        UIColor.yellow

                    sphere.firstMaterial?
                        .emission.contents =
                        UIColor.clear

                } else {

                    sphere.firstMaterial?
                        .diffuse.contents =
                        UIColor.blue

                    sphere.firstMaterial?
                        .emission.contents =
                        UIColor.clear
                }
            }

            node.position =
                SCNVector3(
                    (
                        cell.position.x +
                        cell.displacement.x
                    ) *
                    spacing,

                    (
                        cell.position.y +
                        cell.displacement.y
                    ) *
                    spacing,

                    (
                        cell.position.z +
                        cell.displacement.z
                    ) *
                    spacing
                )
        }
    }

    // ========================================================
    // MARK: - PROTON NODE
    // ========================================================

    private func createProtonNode(
        color: UIColor
    ) -> SCNNode {

        let protonNode =
            SCNNode()

        // Body

        let body =
            SCNSphere(
                radius: 0.38
            )

        let bodyMaterial =
            SCNMaterial()

        bodyMaterial.diffuse.contents =
            color

        bodyMaterial.emission.contents =
            color.withAlphaComponent(
                0.35
            )

        body.firstMaterial =
            bodyMaterial

        let bodyNode =
            SCNNode(
                geometry:
                    body
            )

        protonNode.addChildNode(
            bodyNode
        )

        // Shell

        let shell =
            SCNSphere(
                radius: 0.58
            )

        let shellMaterial =
            SCNMaterial()

        shellMaterial.diffuse.contents =
            color.withAlphaComponent(
                0.10
            )

        shellMaterial.emission.contents =
            color.withAlphaComponent(
                0.25
            )

        shell.firstMaterial =
            shellMaterial

        let shellNode =
            SCNNode(
                geometry:
                    shell
            )

        shellNode.name =
            "shell"

        protonNode.addChildNode(
            shellNode
        )

        // Quark markers

        for index in 0..<3 {

            let quark =
                SCNSphere(
                    radius: 0.075
                )

            quark.firstMaterial =
                SCNMaterial()

            quark.firstMaterial?
                .diffuse.contents =
                UIColor.white

            let qNode =
                SCNNode(
                    geometry:
                        quark
                )

            let angle =
                Float(index) *
                Float.pi *
                2 /
                3

            qNode.position =
                SCNVector3(
                    cos(angle) * 0.22,
                    sin(angle) * 0.22,
                    0
                )

            protonNode.addChildNode(
                qNode
            )
        }

        return protonNode
    }

    // ========================================================
    // MARK: - UPDATE PROTON
    // ========================================================

    private func updateProtonNode(
        _ node: SCNNode,
        proton: QRTLProton,
        color: UIColor
    ) {

        node.position =
            SCNVector3(
                proton.position.x * 0.75,
                proton.position.y * 0.75,
                proton.position.z * 0.75
            )

        guard
            let shell =
                node.childNode(
                    withName:
                        "shell",
                    recursively:
                        false
                ),
            let geometry =
                shell.geometry
                as? SCNSphere
        else {
            return
        }

        geometry.radius =
            CGFloat(
                0.58 +
                min(
                    proton.shellInstability,
                    4
                ) *
                0.20
            )

        geometry.firstMaterial?
            .diffuse.contents =
            color.withAlphaComponent(
                0.10
            )

        geometry.firstMaterial?
            .emission.contents =
            color.withAlphaComponent(
                0.25
            )
    }

    // ========================================================
    // MARK: - HIGGS NODE
    // ========================================================

    private func updateHiggsNode(
        _ node: SCNNode,
        mode: HiggsLikeMode
    ) {

        guard mode.active else {

            node.isHidden =
                true

            return
        }

        node.isHidden =
            false

        node.position =
            SCNVector3(
                0,
                0,
                0
            )

        if node.childNodes.isEmpty {

            let sphere =
                SCNSphere(
                    radius: 0.8
                )

            let material =
                SCNMaterial()

            material.diffuse.contents =
                UIColor.purple.withAlphaComponent(
                    0.30
                )

            material.emission.contents =
                UIColor.purple.withAlphaComponent(
                    0.55
                )

            sphere.firstMaterial =
                material

            node.addChildNode(
                SCNNode(
                    geometry:
                        sphere
                )
            )
        }

        if let sphereNode =
            node.childNodes.first,
           let sphere =
            sphereNode.geometry
            as? SCNSphere {

            sphere.radius =
                CGFloat(
                    0.6 +
                    mode.amplitude *
                    2.0
                )
        }
    }

    // ========================================================
    // MARK: - COORDINATOR
    // ========================================================

    final class Coordinator {

        weak var cameraNode:
            SCNNode?

        var latticeNodes:
            [SCNNode] = []

        var proton1Node:
            SCNNode = SCNNode()

        var proton2Node:
            SCNNode = SCNNode()

        var higgsNode:
            SCNNode = SCNNode()
    }
}

// ============================================================
// MARK: - PREVIEW
// ============================================================

#Preview {
    ContentView()
}
