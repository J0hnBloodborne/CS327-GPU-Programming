#include "../include/mat_ops.h"

#include <stdexcept>

void mulMat(const flat_mat& a, const flat_mat& b, flat_mat& out) {
	if (a.cols != b.rows) {
		throw std::runtime_error("Matrix dimensions are incompatible for multiplication");
	}

	out.rows = a.rows;
	out.cols = b.cols;
	out.data.assign(static_cast<size_t>(out.rows) * out.cols, 0);

	for (int i = 0; i < a.rows; ++i) {
		for (int k = 0; k < a.cols; ++k) {
			const long long aVal = a.data[i * a.cols + k];
			for (int j = 0; j < b.cols; ++j) {
				out.data[i * out.cols + j] += aVal * b.data[k * b.cols + j];
			}
		}
	}
}