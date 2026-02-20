from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = BASE_DIR / "data"
DATA_DIR.mkdir(exist_ok=True)


def pattern_value(matrix_index, row_index, col_index):
    return ((matrix_index + 1) * 17 + (row_index + 1) * 31 + (col_index + 1) * 13) % 97 + 1


def build_row(matrix_index, row_index, cols):
    return " ".join(
        str(pattern_value(matrix_index, row_index, col_index))
        for col_index in range(cols)
    ) + "\n"


def gen_file(filenames, a_rows, a_cols, b_cols):
    assert len(filenames) == len(a_rows) == len(a_cols) == len(b_cols)

    for fname, ar, ac, bc in zip(filenames, a_rows, a_cols, b_cols):
        print(f"Generating {fname.name} (A:{ar}x{ac}, B:{ac}x{bc})...")

        with open(fname, "w", buffering=8*1024*1024) as f:  # 8MB buffer
            # New format:
            # line1: number of matrices
            # line2: rows cols for matrix A
            # next rows: matrix A values
            # next line: rows cols for matrix B
            # next rows: matrix B values
            f.write("2\n")

            # Matrix A: ar x ac
            f.write(f"{ar} {ac}\n")
            for row_index in range(ar):
                f.write(build_row(0, row_index, ac))

            # Matrix B: ac x bc
            f.write(f"{ac} {bc}\n")
            for row_index in range(ac):
                f.write(build_row(1, row_index, bc))

    print(f"Generated {len(filenames)} files in {DATA_DIR}")


"""
Generate 10 files (input_size_1.txt to input_size_10.txt),
each with a multipliable rectangular pair:
file 1: A=1000x2000, B=2000x3000
file 2: A=2000x3000, B=3000x4000
...
file 10: A=10000x11000, B=11000x12000

Values are deterministic (non-random) and vary by matrix index, row, and column.
"""
filenames = [DATA_DIR / f"input_size_{i}.txt" for i in range(1, 11)]
a_rows = [1000 * i for i in range(1, 11)]
a_cols = [1000 * (i + 1) for i in range(1, 11)]
b_cols = [1000 * (i + 2) for i in range(1, 11)]

gen_file(filenames, a_rows, a_cols, b_cols)