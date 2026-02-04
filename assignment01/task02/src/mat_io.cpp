#include "../include/mat_io.h"

std::vector<mat> readMat(std::string in)
{
    FILE* inputFile;
    if (fopen_s(&inputFile, in.c_str(), "r") != 0 || inputFile == nullptr) {
        throw std::runtime_error("Failed to open input file");
    }
    int mats, rows, cols;
    if (fscanf_s(inputFile, "%d %d %d", &mats, &rows, &cols) != 3) throw std::runtime_error("Invalid file format");

    std::vector<mat> m(mats, mat(rows, std::vector<int>(cols)));

    for (int k = 0; k < mats; ++k) {
        for (int i = 0; i < rows; ++i) {
            for (int j = 0; j < cols; ++j) {
                if (fscanf_s(inputFile, "%d", &m[k][i][j]) != 1) {
                    throw std::runtime_error("Invalid matrix data");
                }
            }
        }
    }
    return m;
}

void writeMat(std::string out, mat& m)
{
    int rows = (int)m.size();
    int cols = (int)m[0].size();
    
    FILE* outputFile;
    if (out == "stdout") {
        outputFile = stdout;
    } 
    else {
        if (fopen_s(&outputFile, out.c_str(), "w") != 0 || outputFile == nullptr) {
            throw std::runtime_error("Failed to open output file");
        }
    }
    fprintf(outputFile, "1 %d %d\n", rows, cols);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            fprintf(outputFile, "%d%s", m[i][j], (j == cols - 1 ? "" : " "));
        }
        fprintf(outputFile, "\n");
    }
    if (out != "stdout") fclose(outputFile);
    else { printf("Output written to stdout.\n"); }
}