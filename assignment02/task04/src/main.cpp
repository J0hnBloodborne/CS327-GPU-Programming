#include <iostream>
#include <stdexcept>
#include "../include/mat_ops.cuh"
#include "../include/mat_ops.h"
#include "../include/mat_io.h"
#include "../include/timer.h"   

int main()
{
    FILE* csv = nullptr;
    if (fopen_s(&csv, "../../data/results.csv", "w") != 0 || csv == nullptr) {
        std::cerr << "Failed to open data/results.csv for writing\n";
        return 1;
    }
    std::fprintf(csv, "file,rows,cols,cpu_ms,gpu_ms\n");
    // Read all 10 inputs from /data and load them into RAM
    mat matsM[10];
    mat matsN[10];
    
    for (int i = 0; i < 10; i++) {
        std::cout<< "Loading input file " << i+1 << "\n";
        std::vector<mat> inputMats = readMat("../../data/input_size_" + std::to_string(i+1) + ".txt");
        if (inputMats.size() < 2) {
            throw std::runtime_error("Input must contain at least two matrices");
        }
        matsM[i] = inputMats[0];
        matsN[i] = inputMats[1];
    }
    std::cout<< "Finished loading input files\n";

    // For each input file, time the cpu and gpu multiplication and print to csv
    for (int i = 0; i < 10; i++) {
        mat result;
        double cpu_ms = time_function([&] { mulMat(matsM[i], matsN[i]); });
        double gpu_ms = time_function([&] { mulMatGPU(matsM[i], matsN[i]); });
        printf("Input %d: CPU Time: %.3f ms, GPU Time: %.3f ms\n", i, cpu_ms, gpu_ms);
        std::fprintf(csv, "%d,%d,%.6f,%.6f\n", matsM[i].rows, matsM[i].cols, cpu_ms, gpu_ms);
    }
}
