export vague
export mean, median, mode, shape, scale, rate, var, std, cov, invcov, entropy, pdf, logpdf, logdetcov
export mean_cov, mean_var, mean_invcov, mean_precision, weightedmean_cov, weightedmean_var, weightedmean_invcov, weightedmean_precision
export weightedmean, probvec, logmean, meanlogmean, inversemean, mirroredlogmean, loggammamean
export variate_form, value_support, promote_variate_type, convert_eltype

import Distributions: mean, median, mode, shape, scale, rate, var, std, cov, invcov, entropy, pdf, logpdf, logdetcov
import Distributions: VariateForm, ValueSupport, Distribution

import Base: prod

"""
    vague(distribution_type, [ dims... ])

`vague` function returns uninformative probability distribution of a given type and can be used to set an uninformative priors in a model.
"""
function vague end

mean_cov(something)         = (mean(something), cov(something))
mean_var(something)         = (mean(something), var(something))
mean_invcov(something)      = (mean(something), invcov(something))
mean_precision(something)   = mean_invcov(something)

weightedmean_cov(something)       = (weightedmean(something), cov(something))
weightedmean_var(something)       = (weightedmean(something), var(something))
weightedmean_invcov(something)    = (weightedmean(something), invcov(something))
weightedmean_precision(something) = weightedmean_invcov(something)

probvec(something)         = error("Probability vector function probvec() is not defined for $(something)")
weightedmean(something)    = error("Weighted mean is not defined for $(something)")
inversemean(something)     = error("Inverse expectation is not defined for $(something)")
logmean(something)         = error("Logarithmic expectation is not defined for $(something)")
meanlogmean(something)     = error("xlog(x) expectation is not defined for $(something)")
mirroredlogmean(something) = error("Mirrored Logarithmic expectation is not defined for $(something)")
loggammamean(something)    = error("E[logГ(x)] is not defined for $(something)")

"""
    variate_form(distribution_or_type)

Returns the `VariateForm` sub-type (defined in `Distributions.jl`):

- `Univariate`, a scalar number
- `Multivariate`, a numeric vector
- `Matrixvariate`, a numeric matrix
"""
variate_form(::Distribution{F, S})            where { F <: VariateForm, S <: ValueSupport } = F
variate_form(::Type{ <: Distribution{F, S} }) where { F <: VariateForm, S <: ValueSupport } = F

"""
    value_support(distribution_or_type)

Returns the `ValueSupport` sub-type (defined in `Distributions.jl`):

- `Discrete`, samples take discrete values
- `Continuous`, samples take continuous real values
"""
value_support(::Distribution{F, S})            where { F <: VariateForm, S <: ValueSupport } = S
value_support(::Type{ <: Distribution{F, S} }) where { F <: VariateForm, S <: ValueSupport } = S


"""
    promote_variate_type(::Type{ <: VariateForm }, distribution_type)

Promotes a `distribution_type` to be of the specified variate form (if possible)
"""
function promote_variate_type end

promote_variate_type(::D, T)         where { D <: Distribution } = promote_variate_type(variate_form(D), T)
promote_variate_type(::Type{ D }, T) where { D <: Distribution } = promote_variate_type(variate_form(D), T)

function convert_eltype end

convert_eltype(::Type{ D }, ::Type{ E }, distribution::Distribution) where { D <: Distribution, E } = convert(D{E}, distribution)