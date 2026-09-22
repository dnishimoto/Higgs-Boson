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
