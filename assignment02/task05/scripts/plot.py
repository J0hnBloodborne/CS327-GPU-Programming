# load /data/results.csv and plot the results using matplotlib
import matplotlib.pyplot as plt
import csv
import numpy as np

# Load data from CSV
input_sizes = []
cpu_times = []
gpu_times = []
tiled_times = []
from pathlib import Path

# Locate results.csv by walking up parent directories and looking for data/results.csv
script_dir = Path(__file__).resolve().parent
csv_path = None
for p in [script_dir] + list(script_dir.parents):
    candidate = p / 'data' / 'results2.csv'
    if candidate.exists():
        csv_path = candidate
        break

if csv_path is None:
    raise FileNotFoundError('Could not find data/results.csv in parent directories')

with open(csv_path, 'r') as csvfile:
    reader = csv.reader(csvfile)
    # skip header if present
    try:
        header = next(reader)
    except StopIteration:
        header = None

    for row in reader:
        if not row:
            continue
        # Accept both formats: with or without filename column
        # Possible formats handled:
        # rows,cols,cpu_ms,gpu_ms
        # rows,cols,cpu_ms,gpu_ms,tiled_ms
        # file,rows,cols,cpu_ms,gpu_ms
        # file,rows,cols,cpu_ms,gpu_ms,tiled_ms
        try:
            tiled = None
            if len(row) >= 6:
                # file,rows,cols,cpu_ms,gpu_ms,tiled_ms
                rows = int(row[1])
                cols = int(row[2])
                cpu = float(row[3])
                gpu = float(row[4])
                tiled = float(row[5])
            elif len(row) == 5:
                # could be rows,cols,cpu,gpu,tiled OR file,rows,cols,cpu,gpu
                try:
                    # try rows,cols,cpu,gpu,tiled
                    rows = int(row[0])
                    cols = int(row[1])
                    cpu = float(row[2])
                    gpu = float(row[3])
                    tiled = float(row[4])
                except ValueError:
                    # fallback to file,rows,cols,cpu,gpu (no tiled)
                    rows = int(row[1])
                    cols = int(row[2])
                    cpu = float(row[3])
                    gpu = float(row[4])
            elif len(row) >= 4:
                # rows,cols,cpu,gpu
                rows = int(row[0])
                cols = int(row[1])
                cpu = float(row[2])
                gpu = float(row[3])
            else:
                continue
        except ValueError:
            continue
        input_sizes.append(f"{rows}x{cols}")
        cpu_times.append(cpu)
        gpu_times.append(gpu)
        tiled_times.append(tiled)
    
# line plot
# plot with categorical x-axis (sizes)
x = np.arange(len(input_sizes))
cpu_arr = np.array(cpu_times, dtype=float)
gpu_arr = np.array(gpu_times, dtype=float)
# tiled may contain None; convert to nan for plotting
tiled_arr = np.array([np.nan if t is None else t for t in tiled_times], dtype=float)

plt.figure(figsize=(10, 5))
plt.plot(x, cpu_arr, label='CPU Time (ms)', marker='o', color='blue')
plt.plot(x, gpu_arr, label='GPU Time (ms)', marker='o', color='green')
if not np.all(np.isnan(tiled_arr)):
    plt.plot(x, tiled_arr, label='Tiled GPU Time (ms)', marker='o', color='#006400')
plt.xticks(x, input_sizes, rotation=45)
plt.xlabel('Input Size (Rows x Columns)')
plt.ylabel('Time (ms)')
plt.title('CPU vs GPU vs Tiled GPU Matrix Multiplication Time')
plt.legend()
plt.grid()
plt.tight_layout()
plt.show()

# Second plot: GPU vs Tiled GPU only
plt.figure(figsize=(8, 4))
plt.plot(x, gpu_arr, label='GPU Time (ms)', marker='o', color='green')
if not np.all(np.isnan(tiled_arr)):
    plt.plot(x, tiled_arr, label='Tiled GPU Time (ms)', marker='o', color='red')
plt.xticks(x, input_sizes, rotation=45)
plt.xlabel('Input Size (Rows x Columns)')
plt.ylabel('Time (ms)')
plt.title('GPU vs Tiled GPU Time')
plt.legend()
plt.grid()
plt.tight_layout()
plt.show()
