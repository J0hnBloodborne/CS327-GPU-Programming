#include "../include/mat_io.h"


void get_dims(const std::string& filename, int& n_mats, int& rows, int& cols) {
    FILE* f = nullptr;
    if (fopen_s(&f, filename.c_str(), "r") != 0 || f == nullptr) {
        throw std::runtime_error("Failed to open input file: " + filename);
    }
    if (fscanf_s(f, "%d %d %d", &n_mats, &rows, &cols) != 3) {
        fclose(f);
        throw std::runtime_error("Invalid header in: " + filename);
    }
    fclose(f);
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

std::vector<flat_mat> readMatFlat(const std::string& in) {
    FILE* f = nullptr;
    if (fopen_s(&f, in.c_str(), "r") != 0 || f == nullptr) {
        throw std::runtime_error("Failed to open input file: " + in);
    }

    int n_mats, rows, cols;
    if (fscanf_s(f, "%d %d %d", &n_mats, &rows, &cols) != 3) {
        fclose(f);
        throw std::runtime_error("Invalid header");
    }

    std::vector<flat_mat> result(n_mats);
    int total = rows * cols;

    for (int k = 0; k < n_mats; k++) {
        result[k].rows = rows;
        result[k].cols = cols;
        result[k].data.resize(total);
        for (int i = 0; i < total; i++) {
            if (fscanf_s(f, "%f", &result[k].data[i]) != 1) {
                fclose(f);
                throw std::runtime_error("Invalid matrix data");
            }
        }
    }

    fclose(f);
    return result;
}