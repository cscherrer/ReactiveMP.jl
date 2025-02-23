
# Belief Propagation                #
# --------------------------------- #
@rule MvNormalMeanPrecision(:out, Marginalisation) (m_μ::PointMass, m_Λ::PointMass) = MvNormalMeanPrecision(mean(m_μ), mean(m_Λ))

@rule MvNormalMeanPrecision(:out, Marginalisation) (m_μ::MultivariateNormalDistributionsFamily, m_Λ::PointMass) = begin
    m_μ_mean, m_μ_cov = mean_cov(m_μ)
    return MvNormalMeanCovariance(m_μ_mean, m_μ_cov + cholinv(mean(m_Λ)))
end

# Variational                       # 
# --------------------------------- #
@rule MvNormalMeanPrecision(:out, Marginalisation) (q_μ::Any, q_Λ::Any) = MvNormalMeanPrecision(mean(q_μ), mean(q_Λ))

@rule MvNormalMeanPrecision(:out, Marginalisation) (m_μ::PointMass, q_Λ::Any) = MvNormalMeanPrecision(mean(m_μ), mean(q_Λ))

@rule MvNormalMeanPrecision(:out, Marginalisation) (m_μ::MultivariateNormalDistributionsFamily, q_Λ::Any) = begin 
    m_μ_mean, m_μ_cov = mean_cov(m_μ)
    return MvNormalMeanCovariance(m_μ_mean, m_μ_cov + cholinv(mean(q_Λ)))
end