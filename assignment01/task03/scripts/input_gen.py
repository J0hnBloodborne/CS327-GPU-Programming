import random
MATRICES = 2
ROWS = 1000
COLS = 1000
file = open('./input.txt', 'w')

file.write(f" {MATRICES} {ROWS} {COLS}\n")
for _matrix in range(MATRICES):   
    for _ in range(MATRICES):
        for i in range(ROWS):
            for j in range(COLS):
                file.write(f"{random.randint(-100000, 100000)} ")
        file.write("\n")
file.close()