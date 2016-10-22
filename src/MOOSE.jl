module MOOSE

using JuAFEM

export dofs

export Node, Element, Mesh

export buildSquare

export Variable, System, addVariable!, initialize!

export Solver, solve!, JuliaDenseImplicitSolver

export Kernel, computeResidual!, computeJacobian!, computeResidualAndJacobian!, Diffusion

include("mesh/Mesh.jl")
include("mesh/Generation.jl")
include("systems/System.jl")
include("solvers/Solver.jl")
include("solvers/JuliaDenseImplicitSolver.jl")
include("kernels/Kernel.jl")
include("kernels/Diffusion.jl")

end
