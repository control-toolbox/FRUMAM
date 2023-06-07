using OptimalControl

# Parameters
t0 = 0
tf = 1

# Abstract model
@def ocp begin

    t ∈ [ t0, tf ], time
    x ∈ R², state
    u ∈ R, control

    x(t0) == [ -1, 0 ] 
    x(tf) == [  0, 0 ] 

    ẋ(t) == A*x(t) + B*u(t)

    ∫( 0.5u(t)^2 ) → min

end

A = [ 0 1
      0 0 ]
B = [ 0
      1 ]

# Solve
N = 50
sol = solve(ocp, grid_size=N)

# Plot
plot(sol)
