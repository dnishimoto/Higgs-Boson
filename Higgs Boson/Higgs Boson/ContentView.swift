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




