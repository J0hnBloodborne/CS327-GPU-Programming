#pragma once

#include <string>
#include <vector>

struct mat {
	std::vector<double> data;
	int rows;
	int cols;
};

std::vector<mat> readMat(const std::string& in);
void writeMat(const std::string& out, const mat& m);