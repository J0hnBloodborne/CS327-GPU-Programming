#include "../include/mat_ops.cuh"
#include "../include/mat_io.h"

__global__ void add_mat_1d_kernel(double *acc, const double *mat, size_t total) {
    size_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < total) {
        acc[idx] += mat[idx];
    }
}

void add_mat_gpu_compute_flat(const flat_mat& m1, const flat_mat& m2, flat_mat& result) {
    size_t total = (size_t)m1.rows * m1.cols;
    size_t size = total * sizeof(double);

    double *d_acc, *d_m2;
    cudaMalloc(&d_acc, size);
    cudaMalloc(&d_m2, size);

    cudaMemcpy(d_acc, m1.data.data(), size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_m2, m2.data.data(), size, cudaMemcpyHostToDevice);

    int blockSize = 256;
    int gridSize = (int)((total + blockSize - 1) / blockSize);
    add_mat_1d_kernel<<<gridSize, blockSize>>>(d_acc, d_m2, total);
    cudaDeviceSynchronize();

    result.rows = m1.rows;
    result.cols = m1.cols;
    result.data.resize(total);
    cudaMemcpy(result.data.data(), d_acc, size, cudaMemcpyDeviceToHost);

    cudaFree(d_acc);
    cudaFree(d_m2);
}

void add_nmat_gpu_compute_flat(const std::vector<flat_mat>& mats, flat_mat& result) {
    int n_mats = (int)mats.size();
    if (n_mats == 0) return;

    int rows = mats[0].rows;
    int cols = mats[0].cols;
    size_t total = (size_t)rows * cols;
    size_t size = total * sizeof(double);

    double *d_acc, *d_mat;
    cudaMalloc(&d_acc, size);
    cudaMalloc(&d_mat, size);

    cudaMemcpy(d_acc, mats[0].data.data(), size, cudaMemcpyHostToDevice);

    int blockSize = 256;
    int gridSize = (int)((total + blockSize - 1) / blockSize);

    for (int k = 1; k < n_mats; k++) {
        cudaMemcpy(d_mat, mats[k].data.data(), size, cudaMemcpyHostToDevice);
        add_mat_1d_kernel<<<gridSize, blockSize>>>(d_acc, d_mat, total);
    }
    cudaDeviceSynchronize();

    result.rows = rows;
    result.cols = cols;
    result.data.resize(total);
    cudaMemcpy(result.data.data(), d_acc, size, cudaMemcpyDeviceToHost);

    cudaFree(d_acc);
    cudaFree(d_mat);
}