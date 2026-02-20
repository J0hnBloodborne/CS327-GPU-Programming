#include "../include/mat_ops.cuh"

#include <stdexcept>

mat mulMat(const mat& a, const mat& b) {
	if (a.cols != b.rows) {
		throw std::runtime_error("Matrix dimensions are incompatible for multiplication");
	}
    mat out;
	out.rows = a.rows;
	out.cols = b.cols;
	out.data.assign((int)out.rows * (int)out.cols, 0);

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