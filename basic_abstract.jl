using OptimalControl

# Parameters
t0 = 0
tf = 1

# Abstract model
@def ocp begin

    t ∈ [ t0, tf ], time
    x ∈ R^2, state
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
sol = solve(ocp, grid_size=50)

# Plot
plot(sol)