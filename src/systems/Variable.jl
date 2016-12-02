type Variable{T}
    " Unique Identifier for the variable "
    id::Int64

    " Name of the Variable "
    name::String

    " Current values for this variable indexed by [qp] "
    value::Array{T,1}

    " Current gradients for this variable indexed by [qp] "
    grad::Array{Vec{2,T},1}

    " Current shape functions for this variable indexed by [qp][i] "
    phi::Array{Array{Float64,1}}

    " Current shape function gradients for this variable indexed by [qp][i] "
    grad_phi::Array{Array{Vec{2,Float64}},1}

    " Determinant of the Jacobian pre-multiplied by the weights "
    JxW::Array{Float64,1}

    " Current DoFs "
    dofs::Array{Int64}

    " Current number of dofs on this element "
    n_dofs::Int64

    " Current number of quadrature points on this element "
    n_qp::Int64

    " The value at a node (for use in NodalBCs) "
    nodal_value::T

    " The dof at a node (for use with NodalBCs) "
    nodal_dof::Int64

    Variable(id::Integer, name::String) = new(id, name,
                                              Array{T}(0),
                                              Array{Vec{2,T}}(0),
                                              Array{Array{Float64}}(0),
                                              Array{Array{Vec{2,Float64}},1}(0),
                                              Array{Float64,1}(0),
                                              Array{Int64}(0),
                                              0,
                                              0,
                                              zero(T),
                                              0)
end

" Recompute all of the data inside of a Variable for a given element "
function reinit!{T}(var::Variable, fe_values::FECellValues, dof_indices::Array{Int64}, dof_values::Array{T})
    var.phi = fe_values.N
    var.grad_phi = fe_values.dNdx
    var.JxW = fe_values.detJdV

    n_qp = length(fe_values.detJdV)

    var.value = [function_value(fe_values, qp, dof_values) for qp in 1:n_qp]
    var.grad = [function_gradient(fe_values, qp, dof_values) for qp in 1:n_qp]

    var.dofs = dof_indices
    var.n_dofs = length(dof_values)
    var.n_qp = n_qp
end

" Recompute all of the data inside of a Variable for a given Node "
function reinit!{T}(var::Variable, dof_index::Int64, dof_value::T)
    var.nodal_dof = dof_index
    var.nodal_value = dof_value
end
