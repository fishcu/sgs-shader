import matplotlib.pyplot as plt
import numpy as np

# Define difference equation
def f(y, t, dt, m, c, F):
  # Difference equation for a point mass attached to a damper
  # y: current state (y = [x, v])
  # t: current time
  # dt: time step size
  # m: mass
  # c: damping coefficient
  # F: forcing function
  
  # Extract current position and velocity
  x, v = y
  
  # Compute derivative of state
  dx = v
  dv = (F(t) - c*v) / m
  
  return np.array([dx, dv])

# Define time array
t = np.linspace(0, 100, 100)
dt = t[1] - t[0]

# Define forcing function
def F(t):
  return np.sin(t)

# Initialize state array
y = np.zeros((t.shape[0], 2))

# Set initial position and velocity
y[0,:] = [0, 0]

# Compute step response
for i in range(1, t.shape[0]):
  # Compute midpoint
  t_mid = (t[i] + t[i-1]) / 2
  y_mid = y[i-1] + f(y[i-1], t[i-1], dt, 1, 0.1, F) * dt / 2
  
  # Compute next step
  dy = f(y_mid, t_mid, dt, 1, 0.1, F)
  y[i] = y[i-1] + dy * dt

# Extract position and velocity
x = y[:,0]
v = y[:,1]

# Plot step response
plt.plot(t, x)
plt.show()
