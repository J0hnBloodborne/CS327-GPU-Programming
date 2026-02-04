#include "../include/mat_ops.h"
#include "../include/mat_io.h"

// Flat versions - no 2D overhead
void add_mat_compute_flat(const flat_mat& m1, const flat_mat& m2, flat_mat& result) {
    size_t total = (size_t)m1.rows * m1.cols;
    result.rows = m1.rows;
    result.cols = m1.cols;
    result.data.resize(total);
    for (size_t i = 0; i < total; i++) {
        result.data[i] = m1.data[i] + m2.data[i];
    }
}

void add_nmat_compute_flat(const std::vector<flat_mat>& mats, flat_mat& result) {
    size_t total = (size_t)mats[0].rows * mats[0].cols;
    result.rows = mats[0].rows;
    result.cols = mats[0].cols;
    result.data.assign(total, 0.0f);
    for (size_t k = 0; k < mats.size(); k++) {
        for (size_t i = 0; i < total; i++) {
            result.data[i] += mats[k].data[i];
        }
    }
}