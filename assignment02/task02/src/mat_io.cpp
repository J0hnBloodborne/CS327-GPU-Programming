#include "../include/mat_io.h"

#include <cstdio>
#include <stdexcept>

std::vector<mat> readMat(const std::string& in) {
    FILE* file = nullptr;
    if (fopen_s(&file, in.c_str(), "r") != 0 || file == nullptr) {
        throw std::runtime_error("Failed to open input file: " + in);
    }

    int nMats = 0;
    int rows = 0;
    int cols = 0;
    if (fscanf_s(file, "%d %d %d", &nMats, &rows, &cols) != 3) {
        fclose(file);
        throw std::runtime_error("Invalid input header");
    }

    const int total = rows * cols;
    std::vector<mat> mats(nMats);

    for (int i = 0; i < nMats; ++i) {
        mats[i].rows = rows;
        mats[i].cols = cols;
        mats[i].data.resize(total);

        for (int j = 0; j < total; ++j) {
            if (fscanf_s(file, "%lf", &mats[i].data[j]) != 1) {
                fclose(file);
                throw std::runtime_error("Invalid matrix data");
            }
        }
    }

    fclose(file);
    return mats;
}

void writeMat(const std::string& out, const mat& m) {
    FILE* file = nullptr;
    if (out == "stdout") {
        file = stdout;
    } else if (fopen_s(&file, out.c_str(), "w") != 0 || file == nullptr) {
        throw std::runtime_error("Failed to open output file: " + out);
    }

    fprintf(file, "1 %d %d\n", m.rows, m.cols);
    for (int i = 0; i < m.rows; ++i) {
        for (int j = 0; j < m.cols; ++j) {
            const int index = i * m.cols + j;
            fprintf(file, "%g%s", m.data[index], (j == m.cols - 1 ? "" : " "));
        }
        fprintf(file, "\n");
    }

    if (out != "stdout") {
        fclose(file);
    }
}