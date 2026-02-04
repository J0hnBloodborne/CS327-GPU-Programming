import csv
from pathlib import Path

import matplotlib.pyplot as plt

BASE_DIR = Path(__file__).resolve().parents[1]  # .../task04
DATA_DIR = BASE_DIR / "data"
RESULTS_CSV = DATA_DIR / "results.csv"


def load_results(path=RESULTS_CSV):
    rows = []
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            row["rows"] = int(row["rows"])
            row["cols"] = int(row["cols"])
            row["cpu_ms"] = float(row["cpu_ms"])
            row["gpu_ms"] = float(row["gpu_ms"])
            rows.append(row)
    return rows


def plot_size_sweep(data):
    if not data:
        return
    sizes = [r["rows"] for r in data]
    cpu_times = [r["cpu_ms"] for r in data]
    gpu_times = [r["gpu_ms"] for r in data]

    plt.figure(figsize=(8, 5))
    plt.plot(sizes, cpu_times, marker="o", label="CPU")
    plt.plot(sizes, gpu_times, marker="s", label="GPU")
    plt.xlabel("Matrix dimension N (rows = cols)")
    plt.ylabel("Time (ms)")
    plt.title("Matrix Addition: CPU vs GPU")
    plt.grid(True, linestyle="--", alpha=0.4)
    plt.legend()
    plt.tight_layout()
    plt.savefig(DATA_DIR / "size_vs_time.png", dpi=200)


if not RESULTS_CSV.exists():
    raise SystemExit(f"results.csv not found at {RESULTS_CSV}, run the C++ program first.")

data = load_results()
plot_size_sweep(data)
print(f"Saved plot to: {DATA_DIR / 'size_vs_time.png'}")
