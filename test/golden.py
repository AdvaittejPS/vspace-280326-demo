# golden.py — computes expected NeurAcc output for given weights and inputs
def mac_golden(weights, inputs):
"""
weights: list of 4 integers (0-255)
inputs: list of integers (0-255), one per compute step
returns: list of 4 accumulated results
"""
accums = [0, 0, 0, 0]
NeurAcc — MAC Accelerator Guide | Page 17
for x in inputs:
for i in range(4):
accums[i] += x * weights[i]
return accums
# Test case 1: simple dot product
weights = [1, 2, 3, 4]
inputs = [10, 20, 30]
result = mac_golden(weights, inputs)
print('Test 1 — weights:', weights)
print(' inputs:', inputs)
print(' expected accums:', result)
# Expected: [60, 120, 180, 240]
# accum0 = 10*1 + 20*1 + 30*1 = 60
# accum1 = 10*2 + 20*2 + 30*2 = 120
# accum2 = 10*3 + 20*3 + 30*3 = 180
# accum3 = 10*4 + 20*4 + 30*4 = 240
# Test case 2: all zeros input
weights2 = [5, 10, 15, 20]
inputs2 = [0, 0, 0]
result2 = mac_golden(weights2, inputs2)
print()
print('Test 2 — weights:', weights2)
print(' inputs:', inputs2)
print(' expected accums:', result2)
# Expected: [0, 0, 0, 0]
