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
    
end;

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
plt_sol = plot(direct_sol, size=(700, 700))

# Shooting function
u0 = 0
u1 = 1

H0 = Lift(F0)
H1 = Lift(F1)
H01  = @Poisson { H0, H1 }
H001 = @Poisson { H0, H01 }
H101 = @Poisson { H1, H01 }
us(x, p) = -H001(x, p) / H101(x, p)

g(x) = vmax - constraint(ocp, :eq2)(x, -1)
ub(x)   = -Lie(F0, g)(x) / Lie(F1, g)(x)
μ(x, p) = H01(x, p) / Lie(F1, g)(x)

f0 = Flow(ocp, (x, p, tf) -> u0)
f1 = Flow(ocp, (x, p, tf) -> u1)
fs = Flow(ocp, (x, p, tf) -> us(x, p))
fb = Flow(ocp, (x, p, tf) -> ub(x), (x, u, tf) -> g(x), (x, p, tf) -> μ(x, p))

shoot!(s, p0, t1, t2, t3, tf) = begin

    x1, p1 = f1(t0, x0, p0, t1)
    x2, p2 = fs(t1, x1, p1, t2)
    x3, p3 = fb(t2, x2, p2, t3)
    xf, pf = f0(t3, x3, p3, tf)
    
    s[1] = constraint(ocp, :eq3)(xf, -1) - mf # active final mass constraint
    s[2:3] = pf[1:2] - [ 1, 0 ]
    s[4] = H1(x1, p1)
    s[5] = H01(x1, p1)
    s[6] = g(x2)
    s[7] = H0(xf, pf) # free tf

end

# Initialisation from direct solution
t = direct_sol.times
x = direct_sol.state
u = direct_sol.control
p = direct_sol.costate
φ(t) = H1(x(t), p(t))

u_plot  = plot(t, t -> u(t)[1], label = "u(t)");
H1_plot = plot(t, φ,            label = "H₁(x(t), p(t))");
g_plot  = plot(t, g ∘ x,        label = "g(x(t))");
display(plot(u_plot, H1_plot, g_plot, layout=(3,1), size=(700,700)))

η = 1e-3
t13 = t[ abs.(φ.(t)) .≤ η ]
t23 = t[ 0 .≤ (g ∘ x).(t) .≤ η ]
p0 = p(t0)
t1 = min(t13...)
t2 = min(t23...)
t3 = max(t23...)
tf = t[end]

ξ = [ p0 ; t1 ; t2 ; t3 ; tf ]

println("Initial guess:\n", ξ)

# Indirect solve
nle = (s, ξ) -> shoot!(s, ξ[1:3], ξ[4], ξ[5], ξ[6], ξ[7])
indirect_sol = fsolve(nle, ξ, show_trace=true)
println(indirect_sol)

# Plot
p0 = indirect_sol.x[1:3]
t1 = indirect_sol.x[4]
t2 = indirect_sol.x[5]
t3 = indirect_sol.x[6]
tf = indirect_sol.x[7]

f = f1 * (t1, fs) * (t2, fb) * (t3, f0)
flow_sol = f((t0, tf), x0, p0)
plot!(plt_sol, flow_sol, size=(700, 700))
