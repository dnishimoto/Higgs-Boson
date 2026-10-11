import SwiftUI

struct AboutView: View {
    // The paragraphs, each as a separate card
    private let paragraphs: [String] = [
        "A useful analogy for the proposed QRTL collision is a compressed, spring-loaded crystal. Imagine the two incoming protons as two highly energized structures moving toward one another, with each proton surrounded by an energy shell that behaves somewhat like a deformable protective and energy-storing boundary. As the protons approach, their shells begin to overlap. Instead of simply passing through one another without consequence, the QRTL model treats the overlap as a compression of the underlying lattice. The situation is analogous to pushing two spring-loaded structures together: kinetic energy is temporarily converted into stored deformation energy, while the restoring forces inside the system begin building toward a release.",
        "The QRTL lattice can then be imagined as an enormous three-dimensional network of tiny interconnected springs. Each lattice cell has a local displacement, velocity, strain, phase, twist, and stored energy. When the proton shells collide, the disturbance does not remain confined to one point. The compressed region pushes on neighboring cells, neighboring cells push on their neighbors, and the disturbance begins propagating through the lattice. This is analogous to striking a crystal, a tightly connected spring network, or a drum membrane. The initial localized impact can develop into an organized collective vibration.",
        "The quark components can be represented in the analogy as coupled spring elements inside the compressed region. The two up-type and one down-type quark structures are not treated as independent objects simply moving around randomly. Their twister degrees of freedom interact with the surrounding lattice. One component of the interaction can produce effective attraction toward the compressed region, while another produces repulsion and restoring behavior. The analogy is therefore similar to several coupled springs that are simultaneously being compressed, twisted, and pulled back toward equilibrium.",
        "The twist component is particularly important in the QRTL analogy. Imagine that every spring in the crystal is also capable of twisting. When the collision occurs, the springs do not merely move inward and outward; they can rotate or twist relative to neighboring springs. If neighboring twists become correlated, the disturbance can develop a preferred direction of propagation. This provides the conceptual basis for the proposed borlagrino flow. In the QRTL model, borlagrino flow represents organized redistribution of energy, momentum, phase, and twist through the lattice. The associated charge state is therefore proposed to emerge from the dynamics of the flow rather than being represented as a separate static energy shell.",
        "The analogy can also explain why a collective resonance is different from simply having a large amount of local energy. A crystal can contain a great deal of energy while that energy is distributed among many independent vibrations. A resonance occurs when the motion becomes organized so that many components participate coherently in a particular collective mode. In the QRTL collision, the equivalent process occurs when the initially disordered collision disturbance becomes sufficiently synchronized across the coupled lattice. The collective signal can then reveal a characteristic natural frequency, while the spatial pattern of the oscillating cells identifies the corresponding resonant mode.",
        "This is where the analogy connects to the actual Higgs experiment. ATLAS and CMS observed a new resonance near 125 GeV through statistically significant excesses in reconstructed invariant-mass distributions. The Higgs boson was not observed as a visible object sitting inside the detector. Instead, its presence was inferred from the particles produced by its extremely rapid decay. The analogy is therefore that the QRTL lattice could produce a temporary resonant state in much the same conceptual sense that a struck crystal can produce a short-lived collective vibration. The experimentally established Higgs boson, however, is a quantum field excitation described by the Standard Model; the QRTL lattice resonance is a proposed alternative internal mechanism and has not been experimentally established.",
        "The spring analogy also clarifies the meaning of the approximately 125 GeV value. If two springs are compressed, the total mechanical energy stored in the entire spring system does not necessarily equal the energy of one particular vibration mode. Similarly, the QRTL collision can contain substantially more energy than the energy associated with its proposed Higgs-like collective mode. The approximately 125 GeV quantity should therefore correspond, within the QRTL hypothesis, to the energy of the identified collective resonance rather than to the total energy deposited into the entire lattice.",
        "The same distinction applies to frequency. A spring system has natural frequencies determined by its mass, stiffness, geometry, coupling, and boundary conditions. One does not normally declare that a spring system has a particular frequency merely because one wants it to. The frequency emerges from the physical properties of the system. The QRTL model should follow the same principle: collision energy excites the lattice, the lattice evolves, and the natural or resonant frequency is extracted from the resulting collective motion. Only afterward should the frequency be converted into an energy-equivalent scale and compared with the experimentally measured Higgs mass-energy.",
        "The analogy also provides a way to understand the proposed instability and decay. A highly compressed spring system stores energy and can remain temporarily organized before its restoring forces cause it to release that energy. The QRTL Higgs-like state is proposed to behave similarly. The collision creates a highly compressed and coherent configuration, the configuration becomes a transient collective resonance, and then the balance between attractive, repulsive, restoring, damping, twist, and phase interactions causes the state to become unstable. Its stored excitation is redistributed into other available degrees of freedom.",
        "The proposed weak-like zipper mechanism can be understood through another extension of the analogy. Imagine that the springs in the crystal contain a directional locking mechanism. Once one spring reaches the appropriate excited configuration, it can cause a neighboring spring to adopt a compatible phase and twist. That neighbor then affects the next one, creating a sequential chain of reconfiguration. The process resembles a zipper because the excitation advances step by step rather than appearing everywhere simultaneously. In the QRTL model, the zipper represents coherent propagation of phase and twist information through neighboring lattice cells.",
        "When this propagating excitation reaches the three-twister configuration associated with the proton structure, the model proposes that the internal arrangement can reorganize. The twister configuration changes, the surrounding lattice responds, and the energy shell changes its deformation, phase, or coupling state. Because the QRTL model treats the energy shell as the structure that replaces the conventional electron in its own framework, this shell response is proposed to produce an electron-like excitation.",
        "A remaining coherent disturbance can then propagate outward through the lattice. Within the QRTL hypothesis, this is proposed as a neutral, neutrino-like phase disturbance. Again, the analogy is useful for understanding the proposed mechanism, but it should not be confused with the experimentally established Standard Model description of neutrinos or weak interactions.",
        "The analogy also makes energy conservation easier to visualize. Suppose a compressed spring network initially contains a fixed amount of energy. Energy can move between translational motion, spring compression, vibration, twisting, and other modes, but the network cannot generate additional energy simply because one mode becomes resonant. The QRTL lattice should behave in the same way computationally. The initial proton kinetic energy is the energy budget. Shell compression, lattice motion, strain, twist, phase excitation, collective resonance, and subsequent decay are different forms or locations of that energy. If the simulation reports more final energy than entered the collision, the numerical model has created energy and must be corrected.",
        "Momentum can be understood similarly. Two opposing springs can exert very large forces on one another while the total momentum of the complete isolated system remains balanced. In a symmetric proton collision, the incoming proton momenta can largely cancel in the center-of-momentum frame, while enormous local momentum transfers occur during compression. The QRTL lattice can therefore contain substantial local momentum and motion while the total momentum of the entire system remains conserved.",
        "The analogy consequently provides a simple physical picture of the complete proposed QRTL sequence. Two energized spring-loaded structures collide. Their shells compress. The compression drives a localized region of interconnected springs. The lattice cells begin moving, stretching, and twisting. Neighboring cells become coupled. Energy and momentum redistribute through the lattice. The initially complicated disturbance can organize into a coherent collective vibration. If that mode becomes sufficiently localized, coherent, persistent, and energetically compatible with the approximately 125 GeV experimental Higgs scale, the QRTL model identifies it as a Higgs-like resonance. The resonance subsequently becomes unstable, releases its stored excitation, and transfers energy and momentum into other lattice, shell, and twister degrees of freedom. A proposed zipper-like phase and twist propagation can then reorganize the remaining structure before the lattice relaxes toward equilibrium.",
        "The most important limitation of the analogy is that a spring-loaded crystal is a classical mechanical system, whereas the Higgs boson observed by ATLAS and CMS is a quantum particle associated with the Higgs field. The analogy therefore illustrates the proposed QRTL mechanism; it does not demonstrate that the Higgs boson is literally a mechanical lattice vibration. For the QRTL hypothesis to move beyond analogy, the simulation would need to produce quantitative predictions that can be independently compared with experimental observations, including the resonance mass scale, production behavior, spin and parity characteristics, lifetime, decay channels, branching fractions, and other measurable quantities."
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ForEach(paragraphs.indices, id: \.self) { idx in
                    aboutCard(text: paragraphs[idx], number: idx + 1)
                }
            }
            .padding()
        }
        .navigationTitle("About the QRTL Analogy")
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - About Card
    private func aboutCard(text: String, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.cyan)
                Text("Info Card \(number)")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 15))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}
