#pragma once
#include <vector>
#include "mat_io.h"

void add_mat_gpu_compute_flat(const flat_mat& m1, const flat_mat& m2, flat_mat& result);
void add_nmat_gpu_compute_flat(const std::vector<flat_mat>& mats, flat_mat& result);

void init_gpu(size_t max_elements);
void free_gpu();