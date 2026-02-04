#pragma once
#include <string>
#include <vector>
#include "mat_io.h"

using mat = std::vector<std::vector<int>>;

void add_nmat_gpu(std::string in, std::string out);
void add_mat_gpu(std::string in, std::string out);

void add_mat_gpu_compute(const mat& m1, const mat& m2, mat& result);
void add_nmat_gpu_compute(const std::vector<mat>& mats, mat& result);

// Flat versions (no 2D overhead)
void add_mat_gpu_compute_flat(const flat_mat& m1, const flat_mat& m2, flat_mat& result);
void add_nmat_gpu_compute_flat(const std::vector<flat_mat>& mats, flat_mat& result);