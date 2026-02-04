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



filenames1 = [DATA_DIR / f"input_size_{i}.txt" for i in range(10)]
matrices1 = [2] * 10
sizes = [(i + 1) * 1000 for i in range(10)]
gen_file(filenames1, matrices1, sizes, sizes)