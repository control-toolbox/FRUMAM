using OptimalControl
using MINPACK
using Plots

# Parameters
const Cd = 310
const Tmax = 3.5
const β = 500
const b = 2

t0 = 0
r0 = 1
v0 = 0
vmax = 0.1
m0 = 1
mf = 0.6

# Initial state
x0 = [ r0, v0, m0 ]

# Abstract model
@def ocp begin

    tf, variable
    t ∈ [ t0, tf ], time
    x ∈ R³, state
    u ∈ R, control
    
    r = x₁
    v = x₂
    m = x₃
   
    x(t0) == [ r0, v0, m0 ]
    0  ≤ u(t) ≤ 1
         r(t) ≥ r0,     (1)
    0  ≤ v(t) ≤ vmax,   (2)
    mf ≤ m(t) ≤ m0,     (3)

    ẋ(t) == F0(x(t)) + u(t) * F1(x(t))
 
    r(tf) → max
    
end

F0(x) = begin
    r, v, m = x
    D = Cd * v^2 * exp(-β*(r - 1))
    return [ v, -D/m - 1/r^2, 0 ]
end

F1(x) = begin
    r, v, m = x
    return [ 0, Tmax/m, -b*Tmax ]
end

# Direct solve
N = 50
direct_sol = solve(ocp, grid_size=N)

# Plot
plot(direct_sol, size=(700, 750))
