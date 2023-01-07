import matplotlib.pyplot as plt
import numpy as np

# Simulate step response of a system with overshoot
def step_response(t, K, tau, zeta):
  # Compute the step response of a system with overshoot
  # t: time array
  # K: gain
  # tau: time constant
  # zeta: damping ratio
  
  # Initialize step response array
  y = np.zeros(t.shape)
  
  # Compute step response at each time step
  for i in range(1, t.shape[0]):
    dt = t[i] - t[i-1]
    y[i] = y[i-1] + dt * (-y[i-1]/tau + K/tau) * np.exp(-zeta*t[i])
  
  return y

# Define time array
t = np.linspace(0, 10, 100)

# Compute step response
y = step_response(t, 1, 0.1, 10)

# Plot step response
plt.plot(t, y)
plt.show()
