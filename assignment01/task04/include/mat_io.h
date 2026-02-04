#pragma once
#include <vector>
#include <cstdio>
#include <string>
#include <stdexcept>
using mat = std::vector<std::vector<int>>;

// Flat matrix storage (1D, no nested vectors)
struct flat_mat {
    std::vector<double> data;
    int rows;
    int cols;
};

void get_dims(const std::string& filename, int& n_mats, int& rows, int& cols);
std::vector<mat> readMat(std::string in);
void writeMat(std::string out, mat& m);

// Read matrices as flat 1D arrays (faster, no 2D overhead)
std::vector<flat_mat> readMatFlat(const std::string& in);