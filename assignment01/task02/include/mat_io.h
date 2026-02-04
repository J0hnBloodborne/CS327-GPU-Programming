#include <vector>
#include <cstdio>
#include <string>
#include <stdexcept>
using mat = std::vector<std::vector<int>>;
std::vector<mat> readMat(std::string in);
void writeMat(std::string out, mat& m);