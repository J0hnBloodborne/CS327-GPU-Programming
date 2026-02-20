#include "../include/mat_io.h"

#include <cstdio>
#include <stdexcept>

std::vector<flat_mat> readMat(const std::string& in) {
    FILE* file = nullptr;
    if (fopen_s(&file, in.c_str(), "r") != 0 || file == nullptr) {
        throw std::runtime_error("Failed to open input file: " + in);
    }

    int nMats = 0;
    if (fscanf_s(file, "%d", &nMats) != 1) {
        fclose(file);
        throw std::runtime_error("Invalid input header");
    }

    std::vector<flat_mat> mats(nMats);

    for (int matrixIndex = 0; matrixIndex < nMats; ++matrixIndex) {
        int rows = 0;
        int cols = 0;
        if (fscanf_s(file, "%d %d", &rows, &cols) != 2) {
            fclose(file);
            throw std::runtime_error("Invalid matrix dimension header");
        }

        const int total = rows * cols;
        mats[matrixIndex].rows = rows;
        mats[matrixIndex].cols = cols;
        mats[matrixIndex].data.resize(total);

        for (int elementIndex = 0; elementIndex < total; ++elementIndex) {
            if (fscanf_s(file, "%lld", &mats[matrixIndex].data[elementIndex]) != 1) {
                fclose(file);
                throw std::runtime_error("Invalid matrix data");
            }
        }
    }

    fclose(file);
    return mats;
}

void writeMat(const std::string& out, const flat_mat& m) {
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
            fprintf(file, "%lld%s", m.data[index], (j == m.cols - 1 ? "" : " "));
        }
        fprintf(file, "\n");
    }

    if (out != "stdout") {
        fclose(file);
    }
}