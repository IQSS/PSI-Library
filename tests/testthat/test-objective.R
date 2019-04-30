library(PSIlence)
context("Objective")

### Note: this is extremely cursory testing only to check that integrating new fillMissing function works properly 
#and should not be taken to be exhaustive testing of objective perturbation mechanism.

data(PUMS5extract10000)

n <- 10000
epsilon <- 0.5
rng <- matrix(c(0, 200000, 18, 80, 0, 1), ncol=2, byrow=TRUE)
form <- 'income ~ age + sex'

model <- dpGLM$new(mechanism='mechanismObjective', var.type='numeric', n=10000, epsilon=0.5, 
                   formula=form, rng=rng, objective='ols')
out <- model$release(PUMS5extract10000)
expect_length(out, 4)
