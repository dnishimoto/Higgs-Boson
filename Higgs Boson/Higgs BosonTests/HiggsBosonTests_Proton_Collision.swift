//
//  File.swift
//  Higgs BosonTests
//
//  Created by David Nishimoto on 9/21/26.
//

import XCTest
@testable import Higgs_Boson

final class HiggsBosonTests: XCTestCase {

    // MARK: - Proton Collision Test

    func testTwoProtonsApproachAndCollide() {

        // Same effective timestep used by performFrame()
        let dt = max(QRTLConstants.timeStep, 1.0 / 60.0)

        // Same initial positions used by the simulation
        var protonAX = -QRTLConstants.initialProtonX
        var protonBX = QRTLConstants.initialProtonX

        let collisionDistance = QRTLConstants.collisionDistance
        let speed = QRTLConstants.protonSpeed

        // Initial separation
        var distance = abs(protonBX - protonAX)

        XCTAssertGreaterThan(
            distance,
            collisionDistance,
            "Protons should begin separated."
        )

        var previousDistance = distance
        var collisionOccurred = false

        // Same movement performed by updateProtonApproach(dt:)
        let maximumSteps = 1_000

        for _ in 0..<maximumSteps {

            // Proton A moves toward +X
            protonAX += speed * dt

            // Proton B moves toward -X
            protonBX -= speed * dt

            // Same distance calculation used by the simulation
            distance = abs(protonBX - protonAX)

            // Protons must continuously approach each other
            XCTAssertLessThanOrEqual(
                distance,
                previousDistance,
                "Proton separation increased instead of decreasing."
            )

            // Same collision condition used by updatePhysics()
            if distance <= collisionDistance {
                collisionOccurred = true
                break
            }

            previousDistance = distance
        }

        // Collision must occur
        XCTAssertTrue(
            collisionOccurred,
            "The two protons did not reach the collision distance."
        )

        // Final distance must satisfy the simulation's collision condition
        XCTAssertLessThanOrEqual(
            distance,
            collisionDistance,
            "Collision condition was not reached."
        )
    }

    // MARK: - Collision Energy Test

    func testIncomingProtonKineticEnergy() {

        let expectedEnergyGeV = 13_598.123
        let expectedEnergyTeV = 13.598123
        let expectedEnergyJ = 2.178660e-6

        let actualEnergyGeV =
            QRTLConstants.twoProtonKineticEnergyGeV

        let actualEnergyTeV =
            actualEnergyGeV / 1_000.0

        let actualEnergyJ =
            QRTLConstants.collisionKineticEnergyJ

        // Verify GeV
        XCTAssertEqual(
            actualEnergyGeV,
            expectedEnergyGeV,
            accuracy: 0.01,
            "Two-proton kinetic energy should be approximately 13,598.123 GeV."
        )

        // Verify TeV
        XCTAssertEqual(
            actualEnergyTeV,
            expectedEnergyTeV,
            accuracy: 0.00001,
            "Two-proton kinetic energy should be approximately 13.598123 TeV."
        )

        // Verify joules
        XCTAssertEqual(
            actualEnergyJ,
            expectedEnergyJ,
            accuracy: 1.0e-12,
            "Two-proton kinetic energy should be approximately 2.178660 × 10⁻⁶ J."
        )
    }

    // MARK: - Combined Collision Test

    func testProtonCollisionAndEnergyBudget() {

        // ========================================================
        // Same effective timestep used by performFrame()
        // ========================================================

        let dt = max(
            QRTLConstants.timeStep,
            1.0 / 60.0
        )

        // ========================================================
        // Same initial proton positions used by the simulation
        // ========================================================

        var protonAX = -QRTLConstants.initialProtonX
        var protonBX = QRTLConstants.initialProtonX

        let collisionDistance =
            QRTLConstants.collisionDistance

        let speed =
            QRTLConstants.protonSpeed

        // ========================================================
        // Initial separation
        // ========================================================

        let initialDistance =
            abs(protonBX - protonAX)

        XCTAssertGreaterThan(
            initialDistance,
            collisionDistance,
            "Protons must begin separated."
        )

        // ========================================================
        // Incoming collision energy
        // ========================================================

        let collisionEnergyJ =
            QRTLConstants.collisionKineticEnergyJ

        let collisionEnergyGeV =
            QRTLConstants.twoProtonKineticEnergyGeV

        let collisionEnergyTeV =
            collisionEnergyGeV / 1_000.0

        // ========================================================
        // Validate energy budget
        // ========================================================

        XCTAssertEqual(
            collisionEnergyJ,
            2.178660e-6,
            accuracy: 1.0e-12,
            "Incoming collision energy should be approximately 2.178660 × 10⁻⁶ J."
        )

        XCTAssertEqual(
            collisionEnergyGeV,
            13_598.123,
            accuracy: 0.01,
            "Incoming collision energy should be approximately 13,598.123 GeV."
        )

        XCTAssertEqual(
            collisionEnergyTeV,
            13.598123,
            accuracy: 0.00001,
            "Incoming collision energy should be approximately 13.598123 TeV."
        )

        // ========================================================
        // Approach and collision
        // Same movement used by updateProtonApproach(dt:)
        // ========================================================

        var distance = initialDistance
        var previousDistance = distance
        var collisionOccurred = false

        let maximumSteps = 1_000

        for _ in 0..<maximumSteps {

            // Proton A moves toward +X
            protonAX += speed * dt

            // Proton B moves toward -X
            protonBX -= speed * dt

            // Same distance calculation used by updatePhysics()
            distance = abs(protonBX - protonAX)

            // The protons must continuously approach each other.
            XCTAssertLessThanOrEqual(
                distance,
                previousDistance,
                "Proton separation increased instead of decreasing."
            )

            // Same collision condition used by updatePhysics()
            if distance <= collisionDistance {
                collisionOccurred = true
                break
            }

            previousDistance = distance
        }

        // ========================================================
        // Verify collision
        // ========================================================

        XCTAssertTrue(
            collisionOccurred,
            "The two protons did not reach the collision distance."
        )

        XCTAssertLessThanOrEqual(
            distance,
            collisionDistance,
            "The proton separation must be at or below the collision distance."
        )

        // ========================================================
        // Verify both protons crossed toward the collision point
        // ========================================================

        XCTAssertGreaterThan(
            protonAX,
            -QRTLConstants.initialProtonX,
            "Proton A must move toward the collision point."
        )

        XCTAssertLessThan(
            protonBX,
            QRTLConstants.initialProtonX,
            "Proton B must move toward the collision point."
        )

        // ========================================================
        // Collision energy remains the incoming energy budget
        // ========================================================

        XCTAssertEqual(
            collisionEnergyJ,
            collisionEnergyGeV * QRTLConstants.joulePerGeV,
            accuracy: 1.0e-12,
            "GeV-to-joule conversion must remain consistent."
        )
    }
}
