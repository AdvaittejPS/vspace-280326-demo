# golden.py — computes expected NeurAcc output for given weights and inputs

def mac_golden(weights, inputs):
    """
    weights: list of 4 integers (4-bit, 0-15)
    inputs:  list of integers (8-bit, 0-255), one per compute step
    returns: list of 4 accumulated results (10-bit each)
    """
    accums = [0, 0, 0, 0]
    for x in inputs:
        for i in range(4):
            accums[i] += x * weights[i]
    return accums


if __name__ == "__main__":
    # Test case 1: simple dot product
    weights = [1, 2, 3, 4]
    inputs = [10, 20, 30]
    result = mac_golden(weights, inputs)
    print("Test 1 — weights:", weights)
    print("         inputs: ", inputs)
    print("         expected accums:", result)
    # Expected: [60, 120, 180, 240]

    # Test case 2: all zeros input
    weights2 = [5, 10, 15, 20]
    inputs2 = [0, 0, 0]
    result2 = mac_golden(weights2, inputs2)
    print()
    print("Test 2 — weights:", weights2)
    print("         inputs: ", inputs2)
    print("         expected accums:", result2)
    # Expected: [0, 0, 0, 0]
