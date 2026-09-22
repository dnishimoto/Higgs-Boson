//
//  File.swift
//  Higgs BosonTests
//
//  Created by David Nishimoto on 9/21/26.
//

import Foundation
import XCTest
@testable import Higgs_Boson

final class HiggsBosonModeTests: XCTestCase {

    func testHiggsLikeModeAfterCollision() {
        let simulation = QRTLSimulation()

        let dt =
            max(
                QRTLConstants.timeStep,
                1.0 / 60.0
            )

        // --------------------------------------------------------
        // 1. Advance until the two protons collide.
        // --------------------------------------------------------

        var collisionOccurred = false

        for _ in 0..<1_000 {
            simulation.updatePhysics(dt: dt)

            if simulation.collisionOccurred {
                collisionOccurred = true
                break
            }
        }

        XCTAssertTrue(
            collisionOccurred,
            "Proton collision did not occur."
        )

        // --------------------------------------------------------
        // 2. Advance the post-collision lattice.
        //
        // This allows:
        // collision
        // → lattice excitation
        // → cell motion
        // → collective measurement
        // → Higgs-like mode update
        // --------------------------------------------------------

        for _ in 0..<200 {
            simulation.updatePhysics(dt: dt)
        }

        // --------------------------------------------------------
        // 3. Read the Higgs-like state.
        // --------------------------------------------------------

        let mode = simulation.higgsMode

        let diagnostics =
            simulation.collisionEnergyDiagnostics()

        // --------------------------------------------------------
        // 4. Print the complete state.
        // --------------------------------------------------------

        print("""
        
        ================================
        HIGGS-LIKE MODE TEST
        ================================
        
        Collision occurred:
        \(simulation.collisionOccurred)
        
        Lattice energy:
        \(diagnostics.totalLatticeEnergyJ) J
        
        Collision core energy:
        \(diagnostics.coreLatticeEnergyJ) J
        
        Collision mass energy:
        \(diagnostics.massEnergyJ) J
        
        Mass equivalent:
        \(diagnostics.massEquivalentKg) kg
        
        Higgs-like active:
        \(mode.active)
        
        Higgs-like age:
        \(mode.age) s
        
        Higgs-like energy:
        \(mode.energy) J
        
        Resonant frequency:
        \(mode.frequencyHz) Hz
        
        Resonant mass:
        \(mode.massGeV) GeV
        
        Mass distance from 125 GeV:
        \(simulation.massDistanceFromTarget) GeV
        
        Amplitude:
        \(mode.amplitude)
        
        Phase:
        \(mode.phase)
        
        Coherence:
        \(mode.coherence)
        
        Shell energy:
        \(mode.shellEnergy) J
        
        Shell instability:
        \(mode.shellInstability)
        
        Decay progress:
        \(mode.decayProgress)
        
        ================================
        """)

        // --------------------------------------------------------
        // 5. Basic collision/lattice requirements.
        // --------------------------------------------------------

        XCTAssertTrue(
            simulation.collisionOccurred
        )

        XCTAssertGreaterThan(
            diagnostics.totalLatticeEnergyJ,
            0.0,
            "Collision occurred but the lattice has no energy."
        )

        XCTAssertGreaterThan(
            mode.age,
            0.0,
            "Higgs-like mode age was not advanced."
        )

        // --------------------------------------------------------
        // 6. The lattice must produce a measurable collective
        //    frequency before a Higgs-like mode can exist.
        // --------------------------------------------------------

        XCTAssertGreaterThan(
            mode.frequencyHz,
            0.0,
            """
            Resonant frequency is zero.
            The problem is upstream of updateHiggsLikeMode().
            Check measureCollectiveMode() and
            recordCollectiveLatticeSignal().
            """
        )

        // --------------------------------------------------------
        // 7. A measured mode must have energy.
        // --------------------------------------------------------

        XCTAssertGreaterThan(
            mode.energy,
            0.0,
            """
            Higgs-like mode energy is zero.
            Check resonantModeEnergyJ.
            """
        )

        // --------------------------------------------------------
        // 8. The collective motion must have amplitude.
        // --------------------------------------------------------

        XCTAssertGreaterThan(
            mode.amplitude,
            0.0,
            """
            Higgs-like amplitude is zero.
            Check cell.modeCoordinate and the
            energy-weighted collective signal.
            """
        )

        // --------------------------------------------------------
        // 9. The mode must have measurable coherence.
        // --------------------------------------------------------

        XCTAssertGreaterThan(
            mode.coherence,
            0.0,
            """
            Higgs-like coherence is zero.
            Check calculateCollectiveCoherence()
            and the cell phases.
            """
        )

    }

}
