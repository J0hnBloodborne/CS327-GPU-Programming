#include "../include/mat_ops.h"

#include <stdexcept>

mat mulMat(const mat& a, const mat& b) {
	if (a.cols != b.rows) {
		throw std::runtime_error("Matrix dimensions are incompatible for multiplication");
	}
    mat out(a.rows, b.cols);
	for (int i = 0; i < a.rows; ++i) {
		for (int k = 0; k < a.cols; ++k) {
			double aVal = a.data[i * a.cols + k];
			for (int j = 0; j < b.cols; ++j) {
				out.data[i * out.cols + j] += aVal * b.data[k * b.cols + j];
			}
		}
	}
	return out;
}