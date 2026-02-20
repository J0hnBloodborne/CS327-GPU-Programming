from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = BASE_DIR / "data"
DATA_DIR.mkdir(exist_ok=True)

def gen_file(filenames, matrices, rows, cols, value_min=1, value_max=10):
    assert len(filenames) == len(matrices) == len(rows) == len(cols)

    for fname, n_mat, r, c in zip(filenames, matrices, rows, cols):
        print(f"Generating {fname.name} ({n_mat} x {r}x{c})...")
        
        # Pre-build one row string (all same value = fast)
        row_str = " ".join(["67"] * c) + "\n"
        
        with open(fname, "w", buffering=8*1024*1024) as f:  # 8MB buffer
            f.write(f"{n_mat} {r} {c}\n")
            for _ in range(n_mat):
                # Write all rows at once
                f.write(row_str * r)
    
    print(f"Generated {len(filenames)} files in {DATA_DIR}")


"""
Generate 10 files (input_size_1.txt to input_size_10.txt),
each with 2 matrices, with increasing sizes:
file 1: 1000x2000, file 2: 2000x3000, ..., file 10: 10000x11000
"""
filenames = [DATA_DIR / f"input_size_{i}.txt" for i in range(1, 11)]
matrices = [2] * 10
rows = [1000 * i for i in range(1, 11)]
cols = [1000 * (i + 1) for i in range(1, 11)]

gen_file(filenames, matrices, rows, cols)