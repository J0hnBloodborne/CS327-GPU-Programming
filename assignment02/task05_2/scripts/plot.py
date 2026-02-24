# load /data/results3.csv and plot GPU vs Tiled GPU results using matplotlib
import matplotlib.pyplot as plt
import csv
import numpy as np

# Load data from CSV
input_sizes = []
gpu_times = []
tiled_times = []
from pathlib import Path

# Locate results3.csv by walking up parent directories and looking for data/results3.csv
script_dir = Path(__file__).resolve().parent
csv_path = None
for p in [script_dir] + list(script_dir.parents):
    candidate = p / 'data' / 'results3.csv'
    if candidate.exists():
        csv_path = candidate
        break

if csv_path is None:
    raise FileNotFoundError('Could not find data/results3.csv in parent directories')

with open(csv_path, 'r') as csvfile:
    reader = csv.reader(csvfile)
    try:
        header = next(reader)
    except StopIteration:
        header = None

    # Try to map columns from header if available
    gpu_idx = tiled_idx = rows_idx = cols_idx = None
    if header:
        h = [c.strip().lower() for c in header]
        # heuristic matches
        rows_idx = next((i for i,c in enumerate(h) if 'row' in c or 'rows' in c), 0)
        cols_idx = next((i for i,c in enumerate(h) if 'col' in c or 'cols' in c), 1)
        gpu_idx = next((i for i,c in enumerate(h) if 'gpu' in c and 'tiled' not in c and 'time' in c), None)
        if gpu_idx is None:
            gpu_idx = next((i for i,c in enumerate(h) if 'gpu' in c and 'time' in c), None)
        tiled_idx = next((i for i,c in enumerate(h) if 'tiled' in c or ('tile' in c and 'gpu' in c) or ('tiled' in c and 'time' in c)), None)

    for row in reader:
        if not row:
            continue
        try:
            tiled = None
            # If header mapping succeeded, use mapped indices
            if header and gpu_idx is not None:
                rows = int(row[rows_idx])
                cols = int(row[cols_idx])
                gpu = float(row[gpu_idx]) if row[gpu_idx].strip() != '' else None
                if tiled_idx is not None and row[tiled_idx].strip() != '':
                    tiled = float(row[tiled_idx])
            else:
                # No reliable header: extract numeric fields and heuristically pick columns
                numeric = []
                for i, v in enumerate(row):
                    try:
                        val = float(v)
                        numeric.append((i, val))
                    except Exception:
                        continue

                if len(numeric) >= 3:
                    # assume first two numeric columns are rows,cols; last is GPU; second-last is tiled if distinct
                    rows = int(numeric[0][1])
                    cols = int(numeric[1][1])
                    gpu = float(numeric[-1][1])
                    tiled = float(numeric[-2][1]) if len(numeric) >= 4 else None
                else:
                    # fallback to previous positional heuristics
                    if len(row) >= 6:
                        rows = int(row[1]); cols = int(row[2]); gpu = float(row[4]); tiled = float(row[5])
                    elif len(row) == 5:
                        try:
                            rows = int(row[0]); cols = int(row[1]); gpu = float(row[3]); tiled = float(row[4])
                        except ValueError:
                            rows = int(row[1]); cols = int(row[2]); gpu = float(row[4]); tiled = None
                    elif len(row) >= 4:
                        rows = int(row[0]); cols = int(row[1]); gpu = float(row[3]); tiled = None
                    else:
                        continue

            if gpu is None:
                continue
        except Exception:
            continue

        input_sizes.append(f"{rows}x{cols}")
        gpu_times.append(gpu)
        tiled_times.append(tiled)
    
# Plot: GPU vs Tiled GPU only
x = np.arange(len(input_sizes))
gpu_arr = np.array(gpu_times, dtype=float)
tiled_arr = np.array([np.nan if t is None else t for t in tiled_times], dtype=float)

plt.figure(figsize=(8, 4))
plt.plot(x, gpu_arr, label='Tiled GPU Time (ms)', marker='o', color='red')
if not np.all(np.isnan(tiled_arr)):
    plt.plot(x, tiled_arr, label='GPU Time (ms)', marker='o', color='green')
plt.xticks(x, input_sizes, rotation=45)
plt.xlabel('Input Size (Rows x Columns)')
plt.ylabel('Time (ms)')
plt.title('GPU vs Tiled GPU Time')
plt.legend()
plt.grid()
plt.tight_layout()
plt.show()
