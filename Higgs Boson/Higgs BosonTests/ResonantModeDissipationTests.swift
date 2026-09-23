//
//  File.swift
//  Higgs BosonTests
//
//  Created by David Nishimoto on 9/22/26.
//

import Foundation

import XCTest
@testable import Higgs_Boson

final class ResonantModeDissipationTests: XCTestCase {

    // MARK: - Test: Does damping suppress resonant mode energy?

    func testDissipationDoesNotSuppressResonantModeByTenfold() {

        // --------------------------------------------------------
        // Run A: Normal damping
        // --------------------------------------------------------

        let normalSimulation = QRTLSimulation()

        // Use the same initial collision conditions for both runs.
        normalSimulation.reset()

        normalSimulation.runCollisionForTesting(
            damping: QRTLConstants.damping
        )

        let normalLatticeEnergy =
            normalSimulation.totalMechanicalLatticeEnergy()

        let normalResonantEnergyGeV =
            normalSimulation.resonantModeEnergyGeV

        let normalSignal =
            normalSimulation.collectiveSignal

        let normalFrequency =
            normalSimulation.naturalFrequency


        // --------------------------------------------------------
        // Run B: Very low damping
        // --------------------------------------------------------

        let lowDampingSimulation = QRTLSimulation()

        lowDampingSimulation.reset()

        lowDampingSimulation.runCollisionForTesting(
            damping: 0.000001
        )

        let lowDampingLatticeEnergy =
            lowDampingSimulation.totalMechanicalLatticeEnergy()

        let lowDampingResonantEnergyGeV =
            lowDampingSimulation.resonantModeEnergyGeV

        let lowDampingSignal =
            lowDampingSimulation.collectiveSignal

        let lowDampingFrequency =
            lowDampingSimulation.naturalFrequency


        // --------------------------------------------------------
        // Diagnostic output
        // --------------------------------------------------------

        print("""
        
        ========================================================
        DISSIPATION / RESONANCE TEST
        ========================================================
        
        NORMAL DAMPING
        
        Lattice energy:
            \(normalLatticeEnergy) J
        
        Resonant mode energy:
            \(normalResonantEnergyGeV) GeV
        
        Signal samples:
            \(normalSignal.count)
        
        Signal peak:
            \(normalSignal.map { abs($0) }.max() ?? 0.0)
        
        Natural frequency:
            \(normalFrequency) Hz
        
        
        LOW DAMPING
        
        Lattice energy:
            \(lowDampingLatticeEnergy) J
        
        Resonant mode energy:
            \(lowDampingResonantEnergyGeV) GeV
        
        Signal samples:
            \(lowDampingSignal.count)
        
        Signal peak:
            \(lowDampingSignal.map { abs($0) }.max() ?? 0.0)
        
        Natural frequency:
            \(lowDampingFrequency) Hz
        
        ========================================================
        """)


        // --------------------------------------------------------
        // Determine whether damping causes a 10x suppression.
        // --------------------------------------------------------

        guard normalResonantEnergyGeV > 0 else {
            XCTFail("""
            Normal-damping resonantModeEnergyGeV is zero.

            The test cannot determine whether damping causes
            a 10x suppression because there is no measurable
            resonant energy in the baseline case.
            """)
            return
        }

        guard lowDampingResonantEnergyGeV > 0 else {
            XCTFail("""
            Low-damping resonantModeEnergyGeV is zero.

            This indicates that the problem may occur before
            resonant energy calculation, possibly in the
            collective signal or frequency analysis.
            """)
            return
        }


        let resonanceRatio =
            lowDampingResonantEnergyGeV /
            normalResonantEnergyGeV


        print("""
        
        RESONANCE ENERGY RATIO
        
        Low damping / normal damping:
            \(resonanceRatio)x
        
        """)


        // --------------------------------------------------------
        // A 10x increase means damping is strongly suppressing
        // the resonant mode.
        //
        // This test intentionally fails if the difference is
        // >= 10x, because that identifies excessive damping.
        // --------------------------------------------------------

        XCTAssertLessThan(
            resonanceRatio,
            10.0,
            """
            Dissipation appears to suppress resonantModeEnergyGeV
            by at least 10x.

            Normal damping:
                \(normalResonantEnergyGeV) GeV

            Low damping:
                \(lowDampingResonantEnergyGeV) GeV

            Ratio:
                \(resonanceRatio)x
            """
        )
    }


    // MARK: - Test: Energy accounting

    func testCollisionEnergyAccounting() {

        let simulation = QRTLSimulation()

        simulation.reset()

        simulation.runCollisionForTesting(
            damping: QRTLConstants.damping
        )

        let initialEnergy =
            simulation.initialCollisionEnergy

        let latticeEnergy =
            simulation.totalMechanicalLatticeEnergy()

        let ejectedEnergy =
            simulation.ejectedEnergy

        let dissipatedEnergy =
            simulation.dissipatedEnergy


        let accountedEnergy =
            latticeEnergy +
            ejectedEnergy +
            dissipatedEnergy


        let relativeError =
            abs(initialEnergy - accountedEnergy) /
            initialEnergy


        print("""
        
        ========================================================
        ENERGY ACCOUNTING TEST
        ========================================================
        
        Initial:
            \(initialEnergy) J
        
        Lattice:
            \(latticeEnergy) J
        
        Ejected:
            \(ejectedEnergy) J
        
        Dissipated:
            \(dissipatedEnergy) J
        
        Accounted:
            \(accountedEnergy) J
        
        Relative error:
            \(relativeError)
        
        ========================================================
        """)


        // Energy should be accounted for within 1%.
        XCTAssertLessThan(
            relativeError,
            0.01,
            """
            Collision energy is not being accounted for.

            Relative error:
                \(relativeError)

            Missing energy:
                \(initialEnergy - accountedEnergy) J
            """
        )
    }


    // MARK: - Test: Collective signal exists

    func testCollectiveSignalIsProduced() {

        let simulation = QRTLSimulation()

        simulation.reset()

        simulation.runCollisionForTesting(
            damping: QRTLConstants.damping
        )


        let signal = simulation.collectiveSignal

        let peak =
            signal.map { abs($0) }.max() ?? 0.0

        let minimum =
            signal.min() ?? 0.0

        let maximum =
            signal.max() ?? 0.0


        print("""
        
        ========================================================
        COLLECTIVE SIGNAL TEST
        ========================================================
        
        Samples:
            \(signal.count)
        
        Minimum:
            \(minimum)
        
        Maximum:
            \(maximum)
        
        Peak:
            \(peak)
        
        Natural frequency:
            \(simulation.naturalFrequency) Hz
        
        ========================================================
        """)


        XCTAssertGreaterThan(
            signal.count,
            10,
            "Collective signal contains too few samples."
        )

        XCTAssertGreaterThan(
            peak,
            0.0,
            """
            Collective signal has no measurable amplitude.

            Natural frequency will therefore likely remain 0 Hz.
            """
        )
    }
}

