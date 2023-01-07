import sys
import numpy as np
import cv2
import matplotlib.pyplot as plt

def clamp(value, min_value, max_value):
    """Clamp a value between a minimum and maximum value."""
    return max(min(value, max_value), min_value)


if __name__ == "__main__":
    image = cv2.imread(sys.argv[1])
    if image is None:
        print("Failed to load image:", sys.argv[1])
        sys.exit()

    height, width = image.shape[:2]

    cv2.imshow("Image", image)
    cv2.waitKey(0)

    input = image[2, :, 2]

    t = np.linspace(0, input.shape[0] - 1, 400)
    dt = t[1] - t[0]
    print("dt is ", dt)

    pos_gain = 20.0
    neg_gain = 50.0
    damping = 10.0

    # Define difference equation
    def f(y, t, dt, u):
        # Extract current position and velocity
        x, v = y

        # external force
        if u > x:
            F = pos_gain * (u - x)
        else:
            F = neg_gain * (u - x)
        
        # Compute derivative of state
        dx = v
        dv = F - damping * v
    
        return np.array([dx, dv])
    
    # Initialize state array
    y = np.zeros((t.shape[0], 2))
    input_ss = np.zeros((t.shape[0], 2))

    for i in range(1, t.shape[0]):
        u = input[int(t[i])]

        # Compute midpoint
        t_mid = (t[i] + t[i-1]) / 2
        y_mid = y[i-1] + f(y[i-1], t[i-1], dt, u) * dt / 2
        
        # Compute next step
        dy = f(y_mid, t_mid, dt, u)
        y[i] = y[i-1] + dy * dt

        # dy = f(y[i-1], t[i-1], dt, u)
        # y[i] = y[i-1] + dy * dt

        input_ss[i] = u

    plt.plot(input_ss, '-', drawstyle='steps-mid', label = 'input')
    plt.plot(y[:, 0], label = 'output')
    plt.legend()  
    plt.show()

