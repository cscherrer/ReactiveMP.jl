
# Belief Propagation                #
# --------------------------------- #
@rule NormalMeanVariance(:out, Marginalisation) (m_μ::PointMass, m_v::PointMass) = NormalMeanVariance(mean(m_μ), mean(m_v))

@rule NormalMeanVariance(:out, Marginalisation) (m_μ::UnivariateNormalDistributionsFamily, m_v::PointMass) = begin 
    m_μ_mean, m_μ_cov = mean_cov(m_μ)
    return NormalMeanVariance(m_μ_mean, m_μ_cov + mean(m_v))
end

# Variational                       # 
# --------------------------------- #
@rule NormalMeanVariance(:out, Marginalisation) (q_μ::Any, q_v::Any) = NormalMeanVariance(mean(q_μ), mean(q_v))