import Foundation
import simd

class QRTLSimulation {
    // Assuming properties based on usage
    var cells: [Cell] = []
    var latticeExcited: Bool = false

    struct QRTLConstants {
        static let collisionEnergy: Float = 1.0 // example value
    }

    // ========================================================
    // MARK: Collision -> Lattice Oscillation
    // ========================================================
    private func exciteLatticeFromCollision() {
        // Energy is now injected locally at the lattice center cell(s);
        // outward propagation handled by lattice dynamics.

        let centerThreshold: Float = 1.0e-6
        let fullEnergy = QRTLConstants.collisionEnergy

        for index in self.cells.indices {
            let position = self.cells[index].position
            let distance = simd_length(position)

            if distance < centerThreshold {
                // Assign entire collision energy to center cell(s)
                let displacementAmount = sqrt(fullEnergy) * 0.20
                let impulse = sqrt(fullEnergy) * 0.80

                // Direction arbitrarily chosen as normalized position or default x-axis if zero
                let positionLength = simd_length(position)
                let direction: SIMD3<Float>
                if positionLength > 0.0001 {
                    direction = position / positionLength
                } else {
                    direction = SIMD3<Float>(1, 0, 0)
                }

                self.cells[index].displacement += direction * Float(displacementAmount)
                self.cells[index].velocity += direction * Float(impulse)
                self.cells[index].modeCoordinate += displacementAmount
                self.cells[index].modeVelocity += impulse
                self.cells[index].localEnergy += fullEnergy
                self.cells[index].amplitude = max(self.cells[index].amplitude, displacementAmount)
                self.cells[index].couplingState = min(1.0, self.cells[index].couplingState + 0.5)
                self.cells[index].localStrain = min(1.0, self.cells[index].localStrain + 0.5)
            }
        }

        self.latticeExcited = fullEnergy > 0
    }
}

// Assuming definition of Cell struct based on usage
struct Cell {
    var position: SIMD3<Float>
    var displacement: SIMD3<Float>
    var velocity: SIMD3<Float>
    var modeCoordinate: Float
    var modeVelocity: Float
    var localEnergy: Float
    var amplitude: Float
    var couplingState: Float
    var localStrain: Float
}
