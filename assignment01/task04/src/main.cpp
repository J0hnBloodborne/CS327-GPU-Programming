#include <chrono>
#include <cstdio>
#include <iostream>
#include <string>
#include <vector>
#include "../include/mat_io.h"
#include "../include/mat_ops.h"
#include "../include/mat_ops.cuh"
#include "../include/timer.h"

int main() {
    try {
        FILE* csv = nullptr;
        if (fopen_s(&csv, "data/results.csv", "w") != 0 || csv == nullptr) {
            std::cerr << "Failed to open data/results.csv for writing\n";
            return 1;
        }
        std::fprintf(csv, "file,rows,cols,cpu_ms,gpu_ms\n");

        // Warmup GPU
        {
            std::printf("Warming up device...\n");
            flat_mat w1, w2, wr;
            w1.rows = w2.rows = 16; w1.cols = w2.cols = 16;
            w1.data.assign(256, 1); w2.data.assign(256, 1);
            add_mat_gpu_compute_flat(w1, w2, wr);
        }

        // 2 matrices, varying size
        for (int i = 0; i < 10; ++i) {
            std::string filename = "data/input_size_" + std::to_string(i) + ".txt";
            int n_mats = 0, rows = 0, cols = 0;
            get_dims(filename, n_mats, rows, cols);

            std::printf("Processing %s (%dx%d)...\n", filename.c_str(), rows, cols);

            std::vector<flat_mat> mats = readMatFlat(filename);
            flat_mat result;

            double cpu_ms = time_function([&] { add_mat_compute_flat(mats[0], mats[1], result); });
            double gpu_ms = time_function([&] { add_mat_gpu_compute_flat(mats[0], mats[1], result); });
            std::fprintf(csv, "%s,%d,%d,%.6f,%.6f\n", filename.c_str(), rows, cols, cpu_ms, gpu_ms);
        }

        std::fclose(csv);
        std::printf("Done. Results in data/results.csv\n");
        return 0;
    } 
    catch (const std::exception& ex) {
        std::cerr << "Error: " << ex.what() << "\n";
        return 1;
    }
}