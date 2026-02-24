#pragma once

#include <string>
#include <vector>
#include <stdexcept>
class mat {
	public:
    std::vector<double> data;
	int rows;
	int cols;
    mat() : rows(0), cols(0) {}
    mat(int r, int c) : rows(r), cols(c), data(r * c, 0.0) {}
};

std::vector<mat> readMat(const std::string& in);
void writeMat(const std::string& out, const mat& m);