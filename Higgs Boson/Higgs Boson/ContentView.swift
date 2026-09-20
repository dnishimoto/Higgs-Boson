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
        ZStack {
            QRTLSceneView(simulation: simulation)
                .ignoresSafeArea()

            VStack {
                headerPanel
                Spacer()
                informationPanel
            }
        }
        .onAppear {
            simulation.start()
        }
    }

    private var headerPanel: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("QRTL Collision Model")
                    .font(.title2.bold())
                Text(simulation.stage)
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("TIME")
                    .font(.caption)
                Text(String(format: "%.2f", simulation.time))
                    .font(.system(.headline, design: .monospaced))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    private var informationPanel: some View {

        VStack(spacing: 9) {

            metric(
                "QRTL Field",
                simulation.qrtlField
            )

            metric(
                "Borlagrino Flow",
                simulation.borlagrinoFlow
            )

            metric(
                "QRTL Current",
                simulation.qrtlCurrent
            )

            metric(
                "Shell Instability",
                simulation.shellInstability
            )

            metric(
                "Phase Coherence",
                simulation.coherence
            )

            metric(
                "Localized Energy",
                simulation.localizedEnergy
            )

            Divider()

            HStack {

                Text("Higgs-like State")
                    .font(.headline)

                Spacer()

                Text(
                    simulation.higgsState
                )
                .font(.headline)
            }

            HStack {

                Text("Mode Energy")

                Spacer()

                Text(
                    String(
                        format: "%.2f GeV",
                        simulation.higgsEnergy
                    )
                )
                .monospacedDigit()
            }

            HStack {

                Text("Equivalent Mass")

                Spacer()

                Text(
                    String(
                        format: "%.2f GeV/c²",
                        simulation.higgsMass
                    )
                )
                .monospacedDigit()
            }

            HStack {

                Text("Higgs Age")

                Spacer()

                Text(
                    String(
                        format: "%.3f",
                        simulation.higgsAge
                    )
                )
                .monospacedDigit()
            }

            HStack(spacing: 12) {

                Button {
                    simulation.reset()
                } label: {

                    Label(
                        "Reset",
                        systemImage:
                            "arrow.counterclockwise"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {

                    simulation.running.toggle()

                } label: {

                    Label(
                        simulation.running
                        ? "Pause"
                        : "Run",
                        systemImage:
                            simulation.running
                            ? "pause.fill"
                            : "play.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
        .padding()
    }

    private func metric(
        _ title: String,
        _ value: Double
    ) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text(
                String(
                    format: "%.3f",
                    value
                )
            )
            .monospacedDigit()
        }
    }
}


// ============================================================
// MARK: - QUARK
// ============================================================

enum QuarkFlavor {

    case up
    case down
}

struct Quark {

    let flavor: QuarkFlavor

    var position: SIMD3<Float>

    var velocity: SIMD3<Float>

    var phase: Float

    var amplitude: Float

    var energy: Float

    var excitation: Float
}


// ============================================================
// MARK: - QRTL CELL
// ============================================================

struct QRTLCell {

    var position: SIMD3<Float>

    var displacement:
        SIMD3<Float>

    var velocity:
        SIMD3<Float>

    var phase: Float

    var twist: Float

    var amplitude: Float

    var localEnergy: Float

    var strain: Float

    var qrtlField: Float

    var borlagrinoFlow: Float

    var qrtlCurrent: Float

    var excitation: Float
}


// ============================================================
// MARK: - PROTON
// ============================================================

struct QRTLProton {

    var quarks: [Quark]

    var shellEnergy: Double

    var shellRadius: Double

    var shellInstability: Double

    var fieldEnergy: Double

    init() {

        /*
         Proton valence structure:

                 u
                / \
               /   \
              d --- u

         uud
        */

        quarks = [

            Quark(
                flavor: .up,
                position:
                    SIMD3(
                        -0.65,
                        0.30,
                        0
                    ),
                velocity:
                    .zero,
                phase: 0,
                amplitude: 1,
                energy: 1,
                excitation: 0
            ),

            Quark(
                flavor: .down,
                position:
                    SIMD3(
                        0.0,
                        -0.45,
                        0
                    ),
                velocity:
                    .zero,
                phase: 2.1,
                amplitude: 1,
                energy: 1,
                excitation: 0
            ),

            Quark(
                flavor: .up,
                position:
                    SIMD3(
                        0.65,
                        0.30,
                        0
                    ),
                velocity:
                    .zero,
                phase: 4.2,
                amplitude: 1,
                energy: 1,
                excitation: 0
            )
        ]

        shellEnergy = 1
        shellRadius = 2
        shellInstability = 0
        fieldEnergy = 1
    }
}


// ============================================================
// MARK: - HIGGS-LIKE MODE
// ============================================================

struct HiggsLikeMode {

    var active = false

    var age: Double = 0

    var energy: Double = 0

    var mass: Double = 0

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

final class QRTLSimulation:
    ObservableObject {

    @Published var time: Double = 0

    @Published var stage =
        "Stable Proton Lattices"

    @Published var qrtlField: Double = 0

    @Published var borlagrinoFlow: Double = 0

    @Published var qrtlCurrent: Double = 0

    @Published var shellInstability: Double = 0

    @Published var coherence: Double = 0

    @Published var localizedEnergy: Double = 0

    @Published var higgsEnergy: Double = 0

    @Published var higgsMass: Double = 0

    @Published var higgsAge: Double = 0

    @Published var higgsState =
        "Not Formed"

    @Published var running = true

    private var timer: Timer?

    var protonA = QRTLProton()

    var protonB = QRTLProton()

    var higgs = HiggsLikeMode()

    var cells: [QRTLCell] = []

    let gridSize = 17

    init() {

        createField()
    }

    func start() {

        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.025,
            repeats: true
        ) { [weak self] _ in

            guard let self else {
                return
            }

            guard self.running else {
                return
            }

            self.step()
        }
    }

    func reset() {

        time = 0

        qrtlField = 0

        borlagrinoFlow = 0

        qrtlCurrent = 0

        shellInstability = 0

        coherence = 0

        localizedEnergy = 0

        higgsEnergy = 0

        higgsMass = 0

        higgsAge = 0

        higgsState =
            "Not Formed"

        stage =
            "Stable Proton Lattices"

        protonA =
            QRTLProton()

        protonB =
            QRTLProton()

        higgs =
            HiggsLikeMode()

        createField()
    }

    // ========================================================
    // MARK: CELLULAR AUTOMATON
    // ========================================================

    private func createField() {

        cells.removeAll()

        let spacing: Float = 0.7

        for x in 0..<gridSize {

            for y in 0..<gridSize {

                for z in 0..<gridSize {

                    let px =
                        Float(x)
                        - Float(gridSize - 1) / 2

                    let py =
                        Float(y)
                        - Float(gridSize - 1) / 2

                    let pz =
                        Float(z)
                        - Float(gridSize - 1) / 2

                    cells.append(

                        QRTLCell(
                            position:
                                SIMD3(
                                    px * spacing,
                                    py * spacing,
                                    pz * spacing
                                ),
                            displacement:
                                .zero,
                            velocity:
                                .zero,
                            phase:
                                Float.random(
                                    in: 0...(2 * .pi)
                                ),
                            twist: 0,
                            amplitude: 0,
                            localEnergy: 0,
                            strain: 0,
                            qrtlField: 0,
                            borlagrinoFlow: 0,
                            qrtlCurrent: 0,
                            excitation: 0
                        )
                    )
                }
            }
        }
    }

    // ========================================================
    // MARK: TIME STEP
    // ========================================================

    private func step() {

        time += 0.025

        updateCollision()

        updateShellInstability()

        updateQRTLField()

        updateBorlagrinoFlow()

        updateCurrent()

        updateLattice()

        updateCoherence()

        updateLocalizedEnergy()

        updateHiggsMode()

        updateStage()
    }

    // ========================================================
    // MARK: COLLISION
    // ========================================================

    private func updateCollision() {

        /*
         Proton centers move toward each other.
         */

        let approach =
            min(
                1,
                max(
                    0,
                    (time - 0.5) / 2.0
                )
            )

        for i in protonB.quarks.indices {

            let index = Float(i)
            let quarkOffset: Float = (index - 1.0) * 0.6
            let collisionPosition: Float = 5.0 - Float(approach) * 5.0
            let finalX: Float = collisionPosition + quarkOffset

            protonB.quarks[i].position.x = finalX
        }
        
        for i in protonB.quarks.indices {

            let index: Float = Float(i)
            let quarkOffset: Float = (index - 1.0) * 0.6
            let approachValue: Float = Float(approach)
            let collisionPosition: Float =
                5.0 - approachValue * 5.0

            let finalX: Float =
                collisionPosition + quarkOffset

            protonB.quarks[i].position.x = finalX
        }
    }

    // ========================================================
    // MARK: ENERGY SHELL INSTABILITY
    // ========================================================

    private func updateShellInstability() {

        /*
         The instability occurs when the
         two energy shells overlap.

         This is the central assumption of
         the proposed QRTL model.
         */

        let collision =
            smoothStep(
                1.5,
                3.5,
                time
            )

        let impactEnergy =
            collision * 2.0

        let threshold =
            0.85

        shellInstability =
            min(
                1,
                max(
                    0,
                    impactEnergy - threshold
                )
            )

        protonA.shellInstability =
            shellInstability

        protonB.shellInstability =
            shellInstability

        /*
         Instability excites quarks.
         */

        for i in protonA.quarks.indices {

            protonA.quarks[i].excitation =
                Float(shellInstability)

            protonA.quarks[i].energy +=
                Float(
                    shellInstability
                    * 0.08
                )
        }

        for i in protonB.quarks.indices {

            protonB.quarks[i].excitation =
                Float(shellInstability)

            protonB.quarks[i].energy +=
                Float(
                    shellInstability
                    * 0.08
                )
        }
    }

    // ========================================================
    // MARK: QRTL FIELD
    // ========================================================

    private func updateQRTLField() {

        var total = 0.0

        for i in cells.indices {

            let distance =
                simd_length(
                    cells[i].position
                )

            let collisionWave =
                shellInstability
                * exp(
                    -Double(distance)
                    * 0.8
                )

            let phaseWave =
                0.5
                + 0.5
                * sin(
                    Double(time) * 9
                    - Double(distance) * 3
                )

            cells[i].qrtlField =
                Float(
                    collisionWave
                    * phaseWave
                )

            cells[i].excitation =
                cells[i].qrtlField

            total +=
                Double(
                    cells[i].qrtlField
                )
        }

        qrtlField =
            min(
                1,
                total /
                Double(cells.count) * 4
            )
    }

    // ========================================================
    // MARK: BORLAGRINO FLOW
    // ========================================================

    private func updateBorlagrinoFlow() {

        /*
         Flow responds to QRTL-field gradients.

         The model treats the flow as the
         transport mechanism that generates
         the QRTL current.
         */

        var totalFlow = 0.0

        for i in cells.indices {

            let center =
                simd_length(
                    cells[i].position
                )

            let decayArgument: Double =
                Double(-center) * 0.5

            let radialDecay: Double =
                exp(decayArgument)

            let radialFlow: Double =
                shellInstability * radialDecay

            let phaseGradient =
                abs(
                    sin(
                        Double(
                            cells[i].phase
                        )
                        + time * 6
                    )
                )

            let flow =
                radialFlow
                * phaseGradient

            cells[i].borlagrinoFlow =
                Float(flow)

            totalFlow += flow
        }

        borlagrinoFlow =
            min(
                1,
                totalFlow /
                Double(cells.count) * 5
            )
    }

    // ========================================================
    // MARK: QRTL CURRENT
    // ========================================================

    private func updateCurrent() {

        /*
         Borlagrino flow creates QRTL current.

         I_Q ∝ J_B × field coupling
         */

        qrtlCurrent =
            min(
                1,
                borlagrinoFlow
                * (
                    0.6
                    + 0.4 * qrtlField
                )
            )

        for i in cells.indices {

            cells[i].qrtlCurrent =
                Float(
                    cells[i].borlagrinoFlow
                    * (
                        0.6
                        + 0.4
                        * cells[i].qrtlField
                    )
                )
        }
    }

    // ========================================================
    // MARK: LATTICE DEFORMATION
    // ========================================================

    private func updateLattice() {

        for i in cells.indices {

            let p =
                cells[i].position

            let r =
                simd_length(p)

            let wave =
                sin(
                    Float(time * 11)
                    - r * 4
                )

            let deformation =
                Float(
                    shellInstability
                )
                * wave
                * 0.45

            let radial =
                r > 0
                ? p / r
                : SIMD3<Float>.zero

            cells[i].displacement =
                radial * deformation

            cells[i].strain =
                abs(
                    deformation
                )

            cells[i].twist =
                deformation
                * cos(
                    Float(time * 7)
                )
        }
    }

    // ========================================================
    // MARK: PHASE COHERENCE
    // ========================================================

    private func updateCoherence() {

        /*
         Coherence increases when the
         lattice begins oscillating collectively.
         */

        let organization =
            smoothStep(
                4.0,
                9.0,
                time
            )

        coherence =
            min(
                1,
                organization
                * (
                    0.55
                    + 0.45 * qrtlCurrent
                )
            )

        for i in cells.indices {

            cells[i].phase =
                Float(
                    time * 5
                )
                + Float(
                    i % 11
                )
                * Float(
                    0.03
                )
                * Float(
                    1 - coherence
                )
        }
    }

    // ========================================================
    // MARK: ENERGY CONCENTRATION
    // ========================================================

    private func updateLocalizedEnergy() {

        /*
         Energy concentration is an emergent
         combination of field, flow and coherence.
         */

        localizedEnergy =
            min(
                1,
                qrtlField
                * borlagrinoFlow
                * (
                    0.35
                    + 0.65 * coherence
                )
                * 4
            )
    }

    // ========================================================
    // MARK: HIGGS-LIKE FORMATION
    // ========================================================

    private func updateHiggsMode() {

        /*
         The state forms only when the
         collective mode becomes sufficiently
         coherent and localized.
         */

        let formation =
            localizedEnergy
            * coherence
            * qrtlCurrent

        if !higgs.active
            && formation > 0.55 {

            higgs.active = true

            higgs.age = 0

            higgs.amplitude =
                formation

            higgs.coherence =
                coherence

            higgs.shellEnergy =
                localizedEnergy
        }

        guard higgs.active else {

            higgsAge = 0
            higgsEnergy = 0
            higgsMass = 0

            return
        }

        higgs.age += 0.025

        /*
         Natural-mode energy estimate.

         In this conceptual model, the
         coherent mode approaches the
         experimentally observed Higgs
         energy scale without making the
         particle permanent.
         */

        let resonanceEnvelope =
            min(
                1,
                formation
            )

        higgs.energy =
            125.0
            * resonanceEnvelope

        higgs.mass =
            higgs.energy

        higgs.phase +=
            0.025
            * 12.0

        /*
         The key hypothesis:

         The Higgs-like state is itself
         an unstable energy-shell mode.

         As its shell instability rises,
         the coherent state loses amplitude.
         */

        let intrinsicInstability =
            min(
                1,
                higgs.age / 0.35
            )

        let shellFailure =
            max(
                0,
                intrinsicInstability
                - coherence * 0.25
            )

        higgs.shellInstability =
            shellFailure

        higgs.decayProgress =
            shellFailure

        higgs.amplitude =
            formation
            * (
                1
                - shellFailure
            )

        higgsEnergy =
            higgs.energy
            * higgs.amplitude

        higgsMass =
            higgsEnergy

        higgsAge =
            higgs.age

        /*
         Decay when the unstable shell
         can no longer maintain coherence.
         */

        if higgs.amplitude < 0.08 {

            higgs.active = false

            higgsState =
                "Decayed"

            higgsEnergy = 0

            higgsMass = 0

            higgsAge =
                higgs.age
        }
        else {

            higgsState =
                "Higgs-like Excitation"
        }
    }

    // ========================================================
    // MARK: STAGE
    // ========================================================

    private func updateStage() {

        switch time {

        case 0..<1.5:

            stage =
                "Stable uud Proton Lattices"

        case 1.5..<3.5:

            stage =
                "Energy-Shell Collision"

        case 3.5..<5:

            stage =
                "Shell Instability"

        case 5..<6.5:

            stage =
                "Quark + Energy Ejection"

        case 6.5..<8:

            stage =
                "Borlagrino Flow"

        case 8..<10:

            stage =
                "QRTL Current"

        case 10..<12:

            stage =
                "Lattice Phase Organization"

        case 12..<14:

            stage =
                "Energy Concentration"

        default:

            if higgs.active {

                stage =
                    "Higgs-like Resonant State"
            }
            else if higgs.age > 0 {

                stage =
                    "Higgs-like State Decayed"
            }
            else {

                stage =
                    "Collective QRTL Resonance"
            }
        }
    }

    // ========================================================
    // MARK: UTILITY
    // ========================================================

    private func smoothStep(
        _ start: Double,
        _ end: Double,
        _ value: Double
    ) -> Double {

        let x =
            max(
                0,
                min(
                    1,
                    (value - start)
                    / (end - start)
                )
            )

        return x * x * (3 - 2 * x)
    }
}


// ============================================================
// MARK: - 3D SCENE
// ============================================================

struct QRTLSceneView:
    UIViewRepresentable {

    @ObservedObject var simulation:
        QRTLSimulation

    func makeCoordinator()
        -> Coordinator {

        Coordinator(
            simulation: simulation
        )
    }

    func makeUIView(
        context: Context
    ) -> SCNView {

        let view = SCNView()

        view.scene =
            context.coordinator.scene

        view.backgroundColor =
            .black

        view.allowsCameraControl =
            true

        view.autoenablesDefaultLighting =
            true

        view.antialiasingMode =
            .multisampling4X

        return view
    }

    func updateUIView(
        _ view: SCNView,
        context: Context
    ) {

        context.coordinator.update()
    }

    // ========================================================
    // MARK: COORDINATOR
    // ========================================================

    final class Coordinator {

        let simulation:
            QRTLSimulation

        let scene =
            SCNScene()

        let cameraNode =
            SCNNode()

        var quarkNodesA:
            [SCNNode] = []

        var quarkNodesB:
            [SCNNode] = []

        var fieldNodes:
            [SCNNode] = []

        let higgsNode =
            SCNNode()

        init(
            simulation:
                QRTLSimulation
        ) {

            self.simulation =
                simulation

            setup()
        }

        private func setup() {

            setupCamera()

            setupLighting()

            createProtons()

            createQRTLField()

            createHiggs()
        }

        // ====================================================
        // CAMERA
        // ====================================================

        private func setupCamera() {

            let camera =
                SCNCamera()

            camera.fieldOfView =
                55

            cameraNode.camera =
                camera

            cameraNode.position =
                SCNVector3(
                    0,
                    8,
                    22
                )

            scene.rootNode.addChildNode(
                cameraNode
            )

            let target =
                SCNNode()

            scene.rootNode.addChildNode(
                target
            )

            cameraNode.constraints =
                [
                    SCNLookAtConstraint(
                        target: target
                    )
                ]
        }

        // ====================================================
        // LIGHTING
        // ====================================================

        private func setupLighting() {

            let light =
                SCNLight()

            light.type =
                .omni

            light.intensity =
                1600

            let node =
                SCNNode()

            node.light =
                light

            node.position =
                SCNVector3(
                    0,
                    8,
                    8
                )

            scene.rootNode.addChildNode(
                node
            )

            let ambient =
                SCNLight()

            ambient.type =
                .ambient

            ambient.intensity =
                500

            let ambientNode =
                SCNNode()

            ambientNode.light =
                ambient

            scene.rootNode.addChildNode(
                ambientNode
            )
        }

        // ====================================================
        // PROTONS
        // ====================================================

        private func createProtons() {

            for _ in 0..<3 {

                let node =
                    createQuarkNode()

                scene.rootNode.addChildNode(
                    node
                )

                quarkNodesA.append(
                    node
                )
            }

            for _ in 0..<3 {

                let node =
                    createQuarkNode()

                scene.rootNode.addChildNode(
                    node
                )

                quarkNodesB.append(
                    node
                )
            }
        }

        private func createQuarkNode()
            -> SCNNode {

            let sphere =
                SCNSphere(
                    radius: 0.32
                )

            let material =
                SCNMaterial()

            material.diffuse.contents =
                UIColor.white

            material.emission.contents =
                UIColor.white

            sphere.materials =
                [material]

            return SCNNode(
                geometry: sphere
            )
        }

        // ====================================================
        // QRTL FIELD
        // ====================================================

        private func createQRTLField() {

            /*
             Reduced field representation for
             the 3D visualization.
             */

            for _ in 0..<120 {

                let sphere =
                    SCNSphere(
                        radius: 0.035
                    )

                let material =
                    SCNMaterial()

                material.diffuse.contents =
                    UIColor.cyan

                material.emission.contents =
                    UIColor.cyan

                sphere.materials =
                    [material]

                let node =
                    SCNNode(
                        geometry: sphere
                    )

                node.position =
                    SCNVector3(
                        Float.random(
                            in: -6...6
                        ),
                        Float.random(
                            in: -4...4
                        ),
                        Float.random(
                            in: -4...4
                        )
                    )

                scene.rootNode.addChildNode(
                    node
                )

                fieldNodes.append(
                    node
                )
            }
        }

        // ====================================================
        // HIGGS
        // ====================================================

        private func createHiggs() {

            let sphere =
                SCNSphere(
                    radius: 0.85
                )

            let material =
                SCNMaterial()

            material.diffuse.contents =
                UIColor.white

            material.emission.contents =
                UIColor.white

            sphere.materials =
                [material]

            higgsNode.geometry =
                sphere

            higgsNode.position =
                SCNVector3(
                    0,
                    0,
                    0
                )

            higgsNode.opacity =
                0

            scene.rootNode.addChildNode(
                higgsNode
            )

            /*
             Outer shell surrounding the
             Higgs-like excitation.
             */

            let shell =
                SCNSphere(
                    radius: 1.35
                )

            let shellMaterial =
                SCNMaterial()

            shellMaterial.diffuse.contents =
                UIColor.systemPink

            shellMaterial.emission.contents =
                UIColor.systemPink

            shellMaterial.transparency =
                0.18

            shell.materials =
                [shellMaterial]

            let shellNode =
                SCNNode(
                    geometry: shell
                )

            higgsNode.addChildNode(
                shellNode
            )
        }

        // ====================================================
        // UPDATE 3D MODEL
        // ====================================================

        func update() {

            updateQuarks()

            updateField()

            updateHiggs()
        }

        private func updateQuarks() {

            let a =
                simulation.protonA.quarks

            let b =
                simulation.protonB.quarks

            for i in 0..<3 {

                guard i <
                        quarkNodesA.count
                else {
                    continue
                }

                let q =
                    a[i]

                quarkNodesA[i].position =
                    SCNVector3(
                        q.position.x,
                        q.position.y,
                        q.position.z
                    )

                quarkNodesA[i].scale =
                    SCNVector3(
                        1
                        + q.excitation * 0.8,
                        1
                        + q.excitation * 0.8,
                        1
                        + q.excitation * 0.8
                    )
            }

            for i in 0..<3 {

                guard i <
                        quarkNodesB.count
                else {
                    continue
                }

                let q =
                    b[i]

                quarkNodesB[i].position =
                    SCNVector3(
                        q.position.x,
                        q.position.y,
                        q.position.z
                    )

                quarkNodesB[i].scale =
                    SCNVector3(
                        1
                        + q.excitation * 0.8,
                        1
                        + q.excitation * 0.8,
                        1
                        + q.excitation * 0.8
                    )
            }
        }

        private func updateField() {

            let field =
                Float(
                    simulation.qrtlField
                )

            let flow =
                Float(
                    simulation.borlagrinoFlow
                )

            let amplitude =
                0.4
                + field * 1.5
                + flow * 0.8

            for (index, node)
                in fieldNodes.enumerated() {

                let t =
                    Float(
                        simulation.time
                    )

                let phase =
                    t * 5
                    + Float(index)
                    * 0.35

                let original =
                    node.position

                node.position =
                    SCNVector3(
                        original.x,
                        original.y
                        + sin(phase)
                        * amplitude
                        * 0.05,
                        original.z
                    )

                node.scale =
                    SCNVector3(
                        1
                        + field * 1.5,
                        1
                        + field * 1.5,
                        1
                        + field * 1.5
                    )
            }
        }

        private func updateHiggs() {

            let active =
                simulation.higgs.active

            let amplitude =
                Float(
                    simulation.higgs.amplitude
                )

            let age =
                Float(
                    simulation.higgs.age
                )

            if active {

                higgsNode.opacity =
                    CGFloat(
                        amplitude
                    )

                let pulse =
                    1.0
                    + 0.18
                    * sin(
                        age * 18
                    )

                let scale =
                    Float(
                        0.5
                        + amplitude
                        * 1.2
                    )
                    * pulse

                higgsNode.scale =
                    SCNVector3(
                        scale,
                        scale,
                        scale
                    )

                higgsNode.eulerAngles =
                    SCNVector3(
                        age * 2,
                        age * 3,
                        age
                    )
            }
            else {

                /*
                 The Higgs-like state disappears
                 after its unstable shell collapses.
                 */

                higgsNode.opacity = 0

                higgsNode.scale =
                    SCNVector3(
                        0.01,
                        0.01,
                        0.01
                    )
            }
        }
    }
}


// ============================================================
// MARK: - PREVIEW
// ============================================================

#Preview {
    ContentView()
}
