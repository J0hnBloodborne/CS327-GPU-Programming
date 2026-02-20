#pragma once

#include <string>
#include <vector>

struct flat_mat {
	std::vector<long long> data;
	int rows;
	int cols;
};

std::vector<flat_mat> readMat(const std::string& in);
void writeMat(const std::string& out, const flat_mat& m);