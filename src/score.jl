export score, AverageEnergy, DifferentialEntropy, BetheFreeEnergy
export @average_energy

function score end

struct AverageEnergy end
struct DifferentialEntropy end

struct BetheFreeEnergy end

function score(::BetheFreeEnergy, model, scheduler)
    return score(Float64, BetheFreeEnergy(), model, scheduler)
end

function score(::Type{T}, ::BetheFreeEnergy, model, scheduler) where T

    node_bound_free_energies     = map((node) -> score(T, FactorBoundFreeEnergy(), node, scheduler), getnodes(model))
    variable_bound_entropies     = map((v) -> score(T, VariableBoundEntropy(), v, scheduler), getrandom(model))
    node_bound_free_energies_sum = collectLatest(InfCountingReal{T}, InfCountingReal{T}, node_bound_free_energies, reduce_with_sum)
    variable_bound_entropies_sum = collectLatest(InfCountingReal{T}, InfCountingReal{T}, variable_bound_entropies, reduce_with_sum)

    diracs_entropies = Infinity(mapreduce(degree, +, values(getdata(model)), init = 0) + mapreduce(degree, +, values(getconstant(model)), init = 0))

    return combineLatest((node_bound_free_energies_sum, variable_bound_entropies_sum), PushNew()) |> map(T, d -> convert(T, d[1] + d[2] - diracs_entropies))
end

## Average energy function helpers

function score(::AverageEnergy, fform, ::Type{ <: Val }, marginals::Tuple{ <: Marginal{ <: NamedTuple{ N } } }, meta) where N
    return score(AverageEnergy(), fform, Val{ N }, map(as_marginal, values(getdata(marginals[1]))), meta)
end

## Differential entropy function helpers

score(::DifferentialEntropy, marginal::Marginal{ <: NamedTuple }) = mapreduce((d) -> score(DifferentialEntropy(), as_marginal(d)), +, getdata(marginal))
score(::DifferentialEntropy, marginal::Marginal)                  = entropy(marginal)

## Average enery macro helper

macro average_energy(fform, lambda)
    @capture(fform, fformtype_) || error("Error in macro. Functional form specification should in the form of 'fformtype_'")

    fformtype = __extract_fformtype(fformtype)

    @capture(lambda, (args_ where { whereargs__ } = body_) | (args_ = body_)) || error("Error in macro. Lambda body specification is incorrect")
    @capture(args, (inputs__, meta::metatype_) | (inputs__, )) || error("Error in macro. Lambda body arguments speicifcation is incorrect")

    whereargs = whereargs === nothing ? [] : whereargs

    inputs = map(inputs) do input
        @capture(input, iname_::itype_) || error("Error in macro. Input $(input) is incorrect")
        return (iname, itype)
    end

    q_names, q_types, q_init_block = __extract_fn_args_macro_rule(inputs; specname = :marginals, prefix = :q_, proxytype = :Marginal)

    metatype = metatype === nothing ? :Nothing : metatype
    
    result = quote
        function ReactiveMP.score(
            ::AverageEnergy,
            fform           :: $(fformtype),
            marginals_names :: $(q_names),
            marginals       :: $(q_types),
            meta            :: $(metatype)
        ) where { $(whereargs...) }
            $(q_init_block...)
            $(body)
        end
    end
    
    return esc(result)
end