export ModelOptions, model_options
export Model
export getnodes, getrandom, getconstant, getdata
export activate!, repeat!
export UntilConvergence
# export MarginalsEagerUpdate, MarginalsPureUpdate

import Base: show

# Marginals update strategies 

# struct MarginalsEagerUpdate end
# struct MarginalsPureUpdate end

# Model Options

struct ModelOptions{P, F, S}
    pipeline                   :: P
    default_factorisation      :: F
    global_reactive_scheduler  :: S
end

model_options() = model_options(NamedTuple{()}(()))

available_option_names(::Type{ <: ModelOptions }) = (
    :pipeline, 
    :default_factorisation,
    :global_reactive_scheduler, 
    :limit_stack_depth
)

function model_options(options::NamedTuple)
    pipeline                  = EmptyPipelineStage()
    default_factorisation     = FullFactorisation()
    global_reactive_scheduler = AsapScheduler()

    if haskey(options, :pipeline)
        pipeline = options[:pipeline]
    end

    if haskey(options, :default_factorisation)
        default_factorisation = options[:default_factorisation]
    end

    if haskey(options, :global_reactive_scheduler)
        global_reactive_scheduler = options[:global_reactive_scheduler]
    elseif haskey(options, :limit_stack_depth)
        global_reactive_scheduler = LimitStackScheduler(options[:limit_stack_depth]...)
    end

    for key::Symbol in setdiff(union(available_option_names(ModelOptions), fields(options)), available_option_names(ModelOptions))
        @warn "Unknown option key: $key = $(options[key])"
    end

    return ModelOptions(
        pipeline,
        default_factorisation,
        global_reactive_scheduler
    )
end

global_reactive_scheduler(options::ModelOptions) = options.global_reactive_scheduler
get_pipeline_stages(options::ModelOptions)       = options.pipeline
default_factorisation(options::ModelOptions)     = options.default_factorisation

# Model

struct Model{O}
    options  :: O
    nodes    :: Vector{AbstractFactorNode}
    random   :: Vector{RandomVariable}
    constant :: Vector{ConstVariable}
    data     :: Vector{DataVariable}
end

Base.show(io::IO, model::Model) = print(io, "Model($(getoptions(model)))")

Model() = Model(model_options())
Model(options::NamedTuple) = Model(model_options(options))
Model(options::O) where { O <: ModelOptions } = Model{O}(options, Vector{FactorNode}(), Vector{RandomVariable}(), Vector{ConstVariable}(), Vector{DataVariable}())

getoptions(model::Model)  = model.options
getnodes(model::Model)    = model.nodes
getrandom(model::Model)   = model.random
getconstant(model::Model) = model.constant
getdata(model::Model)     = model.data

add!(model::Model, node::AbstractFactorNode)  = begin push!(model.nodes, node); return node end
add!(model::Model, randomvar::RandomVariable) = begin push!(model.random, randomvar); return randomvar end
add!(model::Model, constvar::ConstVariable)   = begin push!(model.constant, constvar); return constvar end
add!(model::Model, datavar::DataVariable)     = begin push!(model.data, datavar); return datavar end
add!(model::Model, ::Nothing)                 = nothing
add!(model::Model, collection::Tuple)         = begin foreach((d) -> add!(model, d), collection); return collection end
add!(model::Model, array::AbstractArray)      = begin foreach((d) -> add!(model, d), array); return array end
add!(model::Model, array::AbstractArray{ <: RandomVariable }) = begin append!(model.random, array); return array end
add!(model::Model, array::AbstractArray{ <: ConstVariable })  = begin append!(model.constant, array); return array end
add!(model::Model, array::AbstractArray{ <: DataVariable })   = begin append!(model.data, array); return array end

function activate!(model::Model) 
    filter!(getrandom(model)) do randomvar
        @assert degree(randomvar) !== 1 "Half-edge has been found: $(name(randomvar)). To terminate half-edges 'Uninformative' node can be used."
        return degree(randomvar) >= 2
    end

    foreach(getdata(model)) do datavar
        if !isconnected(datavar)
            @warn "Unused data variable has been found: '$(name(datavar))'. Ignore if '$(name(datavar))' has been used in deterministic nonlinear tranformation."
        end
    end

    filter!(c -> isconnected(c), getconstant(model))
    foreach(n -> activate!(model, n), getnodes(model))
end

# Utility functions

randomvar(model::Model, args...; kwargs...) = add!(model, randomvar(args...; kwargs...))
constvar(model::Model, args...; kwargs...)  = add!(model, constvar(args...; kwargs...))
datavar(model::Model, args...; kwargs...)   = add!(model, datavar(args...; kwargs...))

as_variable(model::Model, x)                   = add!(model, as_variable(x))
as_variable(model::Model, v::AbstractVariable) = v
as_variable(model::Model, t::Tuple)            = map((d) -> as_variable(model, d), t)

function make_node(model::Model, args...; factorisation = default_factorisation(getoptions(model)), kwargs...) 
    return add!(model, make_node(args...; factorisation = factorisation, kwargs...))
end

# Repeat variational message passing iterations [ EXPERIMENTAL ]

repeat!(model::Model, criterion) = repeat!((_) -> nothing, model, criterion)

function repeat!(callback::Function, model::Model, count::Int)
    for _ in 1:count
        foreach(getdata(model)) do datavar
            resend!(datavar)
        end
        callback(model)
    end
end

struct UntilConvergence{S, F}
    score_type :: S
    tolerance  :: F
    maxcount   :: Int
    mincount   :: Int
end

UntilConvergence(score::S; tolerance::F = 1e-6, maxcount::Int = 10_000, mincount::Int = 0) where { S, F <: Real } = UntilConvergence{S, F}(score, tolerance, maxcount, mincount)
UntilConvergence(; kwargs...)                                                                                     = UntilConvergence(BetheFreeEnergy(); kwargs...)

function repeat!(callback::Function, model::Model, criterion::UntilConvergence{S, F}) where { S, F }

    stopping_fn = let tolerance = criterion.tolerance
        (p) -> abs(p[1] - p[2]) < tolerance
    end

    source = score(F, criterion.score_type, model, AsapScheduler()) |> pairwise() |> map(Bool, stopping_fn)

    is_satisfied     = false
    iterations_count = 0

    subscription = subscribe!(source, lambda(
        on_next     = (v) -> is_satisfied = v,
        on_complete = (v) -> is_satisfied = true
    ))

    while !is_satisfied
        foreach(getdata(model)) do datavar
            resend!(datavar)
        end
        callback(model)
        iterations_count += 1

        if iterations_count <= criterion.mincount
            is_satisfied = false
        end

        if iterations_count >= criterion.maxcount
            is_satisfied = true
        end
    end

    unsubscribe!(subscription)

    return iterations_count
end

# TODO: Feature rejected due to a bug with invalid constant reusing. Should be revisited later.
# function make_node(model::Model, fform, autovar::AutoVar, args::Vararg{ <: ConstVariable{ <: PointMass } }; factorisation = default_factorisation(getoptions(model)), kwargs...)
#     node, var = if haskey(getconstant(model), getname(autovar))
#         nothing, getconstant(model)[ getname(autovar) ]
#     else
#         add!(model, make_node(fform, autovar, args...; factorisation = factorisation, kwargs...))
#     end
# end

# function datavar(model::Model, nameprefix::Symbol, type::Type, dims...) 
#     datavars = datavar(nameprefix, type, dims...)
#     dictvars = Dict(zip(map(name, datavars), datavars))
#     mergewith!((l, r) -> error("DataVariable with name $(name(l)) has already been added to the model"), getdata(model), dictvars)
#     return datavars
# end