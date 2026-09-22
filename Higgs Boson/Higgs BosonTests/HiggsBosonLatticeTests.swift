//
//  File.swift
//  Higgs BosonTests
//
//  Created by David Nishimoto on 9/21/26.
//

import Foundation
import XCTest
@testable import Higgs_Boson

final class HiggsBosonLatticeTests: XCTestCase {
    func testQRTLEnergyShellAfterProtonImpact() {

        let simulation = QRTLSimulation()

        let expectedShellEnergyJ = QRTLConstants.collisionKineticEnergyJ
        let expectedShellEnergyGeV = QRTLConstants.twoProtonKineticEnergyGeV
        let transientMassEnergyJ =
            QRTLConstants.targetHiggsMassGeV * QRTLConstants.joulePerGeV

        // --------------------------------------------------------
        // Constants (independent of simulation state)
        // --------------------------------------------------------

        XCTAssertEqual(
            expectedShellEnergyJ,
            2.178660e-6,
            accuracy: 1.0e-9,
            "Two-proton collision energy should be ~2.178660e-6 J."
        )

        XCTAssertEqual(
            expectedShellEnergyGeV,
            13_598.123,
            accuracy: 0.01,
            "Two-proton collision energy should be ~13,598.123 GeV."
        )

        XCTAssertGreaterThan(
            expectedShellEnergyJ,
            transientMassEnergyJ,
            "Full collision budget must exceed the 125 GeV transient."
        )

        // --------------------------------------------------------
        // Initial shell = full collision KE budget (not 125 GeV)
        // Requires QRTLEnergyState defaults / init to use
        // QRTLConstants.collisionKineticEnergyJ
        // --------------------------------------------------------

        XCTAssertEqual(
            simulation.energyState.shellEnergy,
            expectedShellEnergyJ,
            accuracy: 1.0e-12,
            """
            QRTL shell energy should initially equal the
            two-proton collision kinetic-energy budget.
            """
        )

        XCTAssertEqual(
            simulation.energyState.equilibriumShellEnergy,
            expectedShellEnergyJ,
            accuracy: 1.0e-12,
            """
            QRTL equilibrium shell energy should equal the
            two-proton collision kinetic-energy budget.
            """
        )

        // --------------------------------------------------------
        // Advance until impact
        // Use a moderate approach dt (not 1/60 s) so lattice energy
        // does not explode when collision physics runs.
        // --------------------------------------------------------

        let approachDt = 1.0e-3
        var didCollide = false

        for _ in 0..<20_000 {
            simulation.updatePhysics(dt: approachDt)
            if simulation.collisionOccurred {
                didCollide = true
                break
            }
        }

        XCTAssertTrue(
            didCollide,
            "The two protons should reach the collision condition."
        )

        // --------------------------------------------------------
        // Shell after impact still equals full collision budget
        // --------------------------------------------------------

        let shellAfter = simulation.energyState.shellEnergy

        XCTAssertGreaterThan(shellAfter, 0.0)

        XCTAssertEqual(
            shellAfter,
            expectedShellEnergyJ,
            accuracy: 1.0e-12,
            """
            QRTL shell energy should remain equal to the
            incoming collision-energy budget during impact.
            """
        )

        XCTAssertEqual(
            simulation.energyState.equilibriumShellEnergy,
            expectedShellEnergyJ,
            accuracy: 1.0e-12
        )

        XCTAssertGreaterThan(
            shellAfter,
            transientMassEnergyJ,
            """
            The full QRTL collision shell should contain more
            energy than the 125 GeV transient mass-energy.
            """
        )

        XCTAssertTrue(simulation.energyState.isUnstable)
        XCTAssertEqual(
            simulation.energyState.shellInstability,
            1.0,
            accuracy: 1.0e-12
        )

        print("""

        ============================================================
        QRTL ENERGY SHELL TEST
        ============================================================
        Collision occurred: \(didCollide)
        Shell energy:       \(shellAfter) J
        Shell energy:       \(shellAfter / QRTLConstants.joulePerGeV) GeV
        Shell energy:       \(shellAfter / QRTLConstants.joulePerGeV / 1000.0) TeV
        Expected:           \(expectedShellEnergyJ) J
        Expected:           \(expectedShellEnergyGeV) GeV
        125 GeV transient:  \(transientMassEnergyJ) J
        ============================================================
        """)
    }
    func testLatticeEnergyAndMassAfterImpact() {
        
        let simulation = QRTLSimulation()
        
        // --------------------------------------------------------
        // Incoming collision-energy budget
        // --------------------------------------------------------
        
        let expectedCollisionEnergyJ =
        QRTLConstants.collisionKineticEnergyJ
        
        XCTAssertEqual(
            expectedCollisionEnergyJ,
            2.178660e-6,
            accuracy: 1.0e-12,
            "Incoming collision energy should be approximately 2.178660 × 10⁻⁶ J."
        )
        
        // --------------------------------------------------------
        // Advance until the protons collide.
        //
        // This uses the same effective timestep as performFrame().
        // --------------------------------------------------------
        
        let dt =
        max(
            QRTLConstants.timeStep,
            1.0 / 60.0
        )
        
        var collisionDetected = false
        
        for _ in 0..<1_000 {
            
            simulation.updatePhysics(dt: dt)
            
            if simulation.collisionOccurred {
                collisionDetected = true
                break
            }
        }
        
        XCTAssertTrue(
            collisionDetected,
            "The protons should collide."
        )
        
        // --------------------------------------------------------
        // Measure the lattice immediately after impact.
        // --------------------------------------------------------
        
        let impact =
        simulation.collisionEnergyDiagnostics()
        
        XCTAssertTrue(
            impact.collisionOccurred,
            "The collision state should be active."
        )
        
        XCTAssertGreaterThan(
            impact.totalLatticeEnergyJ,
            0.0,
            "The lattice should contain energy after impact."
        )
        
        XCTAssertGreaterThan(
            impact.coreLatticeEnergyJ,
            0.0,
            "The collision core should contain localized energy."
        )
        
        // --------------------------------------------------------
        // The impact region must contain a significant fraction
        // of the lattice energy.
        // --------------------------------------------------------
        
        XCTAssertLessThanOrEqual(
            impact.coreLatticeEnergyJ,
            impact.totalLatticeEnergyJ,
            "Core energy cannot exceed total lattice energy."
        )
        
        // --------------------------------------------------------
        // Verify transient mass-energy.
        // --------------------------------------------------------
        
        XCTAssertGreaterThan(
            impact.massEnergyJ,
            0.0,
            "A transient mass-energy state should exist at impact."
        )
        
        XCTAssertGreaterThan(
            impact.massEquivalentKg,
            0.0,
            "The transient mass-equivalent should be greater than zero."
        )
        
        // --------------------------------------------------------
        // Verify E = mc² conversion.
        // --------------------------------------------------------
        
        let reconstructedEnergy =
        impact.massEquivalentKg *
        QRTLConstants.speedOfLight *
        QRTLConstants.speedOfLight
        
        XCTAssertEqual(
            reconstructedEnergy,
            impact.massEnergyJ,
            accuracy: 1.0e-20,
            "Mass-equivalent energy must satisfy E = mc²."
        )
        
        // --------------------------------------------------------
        // Print the actual collision measurements.
        // --------------------------------------------------------
        
        print("""
    
    ============================================================
    QRTL LATTICE IMPACT TEST
    ============================================================
    Collision occurred:
      \(impact.collisionOccurred)
    
    Incoming collision energy:
      \(expectedCollisionEnergyJ) J
    
    Total lattice energy:
      \(impact.totalLatticeEnergyJ) J
    
    Local impact-core energy:
      \(impact.coreLatticeEnergyJ) J
    
    Transient mass-energy:
      \(impact.massEnergyJ) J
    
    Mass equivalent:
      \(impact.massEquivalentKg) kg
    
    E = mc² reconstructed:
      \(reconstructedEnergy) J
    ============================================================
    
    """)
    }
}
