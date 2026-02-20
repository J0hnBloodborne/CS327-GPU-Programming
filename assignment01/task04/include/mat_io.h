#pragma once
#include <vector>
#include <cstdio>
#include <string>
#include <stdexcept>
using mat = std::vector<std::vector<int>>;
struct flat_mat {
    std::vector<float> data;
    int rows;
    int cols;
};

void get_dims(const std::string& filename, int& n_mats, int& rows, int& cols);
// std::vector<mat> readMat(std::string in);
void writeMat(std::string out, mat& m);

std::vector<flat_mat> readMatFlat(const std::string& in);