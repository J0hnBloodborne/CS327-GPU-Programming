#pragma once
#include <string>
#include <vector>
#include "mat_io.h"

using mat = std::vector<std::vector<int>>;

void add_mat_compute_flat(const flat_mat& m1, const flat_mat& m2, flat_mat& result);
void add_nmat_compute_flat(const std::vector<flat_mat>& mats, flat_mat& result);