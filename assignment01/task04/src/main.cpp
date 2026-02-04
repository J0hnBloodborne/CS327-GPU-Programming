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

        // Precompute filenames and maximum matrix size so we can preallocate GPU buffers
        std::vector<std::string> filenames;
        filenames.reserve(10);
        size_t max_elems = 0;
        for (int i = 0; i < 10; ++i) {
            std::string filename = "data/input_size_" + std::to_string(i) + ".txt";
            filenames.push_back(filename);
            int n_mats = 0, rows = 0, cols = 0;
            get_dims(filename, n_mats, rows, cols);
            size_t elems = (size_t)rows * cols;
            if (elems > max_elems) max_elems = elems;
        }

        init_gpu(max_elems);

        // Warmup GPU
        std::printf("Warming up device...\n");
        {
            flat_mat w1, w2, wr;
            w1.rows = w2.rows = 16; w1.cols = w2.cols = 16;
            w1.data.assign(256, 1.0f); w2.data.assign(256, 1.0f);
            add_mat_gpu_compute_flat(w1, w2, wr);
        }

        // 2 matrices, varying size
        for (const auto &filename : filenames) {
            int n_mats = 0, rows = 0, cols = 0;
            get_dims(filename, n_mats, rows, cols);

            std::printf("Processing %s (%dx%d)...\n", filename.c_str(), rows, cols);

            std::vector<flat_mat> mats = readMatFlat(filename);
            flat_mat result;

            double cpu_ms = time_function([&] { add_mat_compute_flat(mats[0], mats[1], result); });
            double gpu_ms = time_function([&] { add_mat_gpu_compute_flat(mats[0], mats[1], result); });
            std::fprintf(csv, "%s,%d,%d,%.6f,%.6f\n", filename.c_str(), rows, cols, cpu_ms, gpu_ms);
        }

        free_gpu();

        std::fclose(csv);
        std::printf("Done. Results in data/results.csv\n");
        return 0;
    } 
    catch (const std::exception& ex) {
        std::cerr << "Error: " << ex.what() << "\n";
        return 1;
    }
}