# import cv2
import argparse
import sys
import numpy as np

def lerp(a, b, w):
    return a + (b - a) * w

def generate_mask_pattern(length, fineness, brightness):
    # Number of groups is in [1, length // 2]
    num_groups = int(lerp(1, length // 2, fineness))
    # Num active pixels is between 1 per group,
    # and filling all pixels except gaps between groups
    tot_num_active = int(lerp(num_groups, length - num_groups, brightness))

    # Help with subpixel color shift
    # length *= 3
    # num_groups *= 3
    # num_groups = int(lerp(3, length // 2, fineness))
    # tot_num_active = int(lerp(num_groups, length - num_groups, brightness))
    # tot_num_active *= 3
    # print(f"corrected length = {length}")
    # print(f"num groups = {num_groups}")
    # print(f"total num active = {tot_num_active}")


    # Bresenham-style algorithm
    pattern = [0] * length
    accum_error = -length
    active_accum_error = -tot_num_active
    
    for i in range(0, length):
        # print(f"== at idx {i}")
        # print(f"accum error is {accum_error}")
        if (accum_error >= 0):
            accum_error -= length
            # print("so we start a new group")
            active_accum_error -= tot_num_active  
        
        accum_error += num_groups

        # print(f"accum error is {accum_error}")
        # print(f"{accum_error} < {active_threshold}?")
        # if accum_error < active_threshold:
        #     pattern[i] = 1
        #     print("so we set the current index to active.")

        # print(f"{active_accum_error} < {0}?")
        if active_accum_error < 0 and accum_error < 0:
            # print("set active")
            pattern[i] = 1
            active_accum_error += num_groups

    
    return pattern

def verify_pattern(pattern, length, fineness, brightness):
    assert pattern[0] == 1
    assert pattern[-1] == 0
    expected_num_groups = int(lerp(1, length // 2, fineness))
    expected_tot_num_active = int(lerp(expected_num_groups, length - expected_num_groups, brightness))
    
    # expected_num_groups *= 3
    # expected_tot_num_active *= 3

    actual_num_groups = 1
    actual_tot_num_active = 0
    r = g = b = 0
    for i, x in enumerate(pattern):
        if x == 1:
            actual_tot_num_active += 1
            if i % 3 == 0:
                r += 1
            elif i % 3 == 1:
                g += 1
            else:
                b += 1
        if i > 0 and x == 1 and pattern[i-1] == 0:
            actual_num_groups += 1
    print(actual_num_groups, expected_num_groups)
    assert actual_num_groups == expected_num_groups
    print(actual_tot_num_active, expected_tot_num_active)
    assert actual_tot_num_active == expected_tot_num_active
    print(r, g, b)
    # assert r == g
    # assert r == b


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('length', type = int)
    parser.add_argument('fineness', type = float)
    parser.add_argument('brightness', type = float)
    args = parser.parse_args()
    if len(sys.argv) != 4:
        parser.print_help()
        sys.exit(1)

    pattern = generate_mask_pattern(args.length, args.fineness, args.brightness)
    print(pattern)
    verify_pattern(pattern, args.length, args.fineness, args.brightness)
    print("\n\n")
    sys.exit(0)

    # test
    for l in range(2, 33):
        for f in np.arange(0, 1.1, 0.1):
            for b in np.arange(0, 1.1, 0.1):
                print("\n", l, f, b)
                pattern = generate_mask_pattern(l, f, b)
                print(pattern)
                verify_pattern(pattern, l, f, b)
    
    

