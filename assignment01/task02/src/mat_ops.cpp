#include "../include/mat_ops.h"
#include "../include/mat_io.h"

void add_nmat(std::string in, std::string out)
{
    std::vector<mat> m = readMat(in);
    if (m.size() < 2) throw std::runtime_error("Need at least 2 matrices to add");
    int rows = (int)m[0].size();
    int cols = (int)m[0][0].size();
    mat result(rows, std::vector<int>(cols));
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            result[i][j] = m[0][i][j] + m[1][i][j];
        }
    }
    writeMat(out, result);
    printf("Matrices added successfully.\n");
}

void add_mat(std::string in, std::string out)
{
    std::vector<mat> m = readMat(in);
    if (m.size() != 2) throw std::runtime_error("Input file must contain exactly 2 matrices");
    int rows = (int)m[0].size();
    int cols = (int)m[0][0].size();
    mat result(rows, std::vector<int>(cols));
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            result[i][j] = m[0][i][j] + m[1][i][j];
        }
    }
    writeMat(out, result);
    printf("Matrices added successfully.\n");
}