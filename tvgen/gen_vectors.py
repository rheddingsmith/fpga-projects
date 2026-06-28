import random

N = 64
random.seed(42)

directed = [(0,0), (255, 255), (0,255), (255,0), (1,1), (128,128), (254,1)]

cases = list(directed)

while len(cases) < N:
    a = random.randint(0, 255)
    b = random.randint(0, 255)
    cases.append((a,b))

with open("vectors.hex", "w") as f:
    for a, b in cases:
        expected = (a + b) & 0x1FF
        f.write(f"{a:03x}\n{b:03x}\n{expected:03x}\n")

print(f"Wrote {len(cases)} vectors ({len(cases)*3} values) to vectors.hex")

