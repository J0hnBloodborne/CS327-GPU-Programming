# load /data/results.csv and plot the results using matplotlib
import matplotlib.pyplot as plt
import csv

# Load data from CSV
input_sizes = []
cpu_times = []
gpu_times = []
from pathlib import Path

# Locate results.csv by walking up parent directories and looking for data/results.csv
script_dir = Path(__file__).resolve().parent
csv_path = None
for p in [script_dir] + list(script_dir.parents):
    candidate = p / 'data' / 'results.csv'
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
        # Possible formats:
        # rows,cols,cpu_ms,gpu_ms
        # file,rows,cols,cpu_ms,gpu_ms
        try:
            if len(row) >= 5:
                rows = int(row[1])
                cols = int(row[2])
                cpu = float(row[3])
                gpu = float(row[4])
            elif len(row) >= 4:
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
    
# line plot
# plot with categorical x-axis (sizes)
x = list(range(len(input_sizes)))
plt.plot(x, cpu_times, label='CPU Time (ms)', marker='o', color='blue')
plt.plot(x, gpu_times, label='GPU Time (ms)', marker='o', color='green')
plt.xticks(x, input_sizes, rotation=45)
plt.xlabel('Input Size (Rows x Columns)')
plt.ylabel('Time (ms)')
plt.title('CPU vs GPU Matrix Multiplication Time')
plt.legend()
plt.grid()
plt.tight_layout()
plt.show()
