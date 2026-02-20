#include "../include/mat_ops.cuh"
#include "../include/mat_io.h"
#include <cuda_runtime.h>

static float *g_d_acc = nullptr;
static float *g_d_mat = nullptr;
static size_t g_alloc_elems = 0;


__global__ void add_mat_1d_kernel(float *acc, const float *mat, size_t total) {
    size_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < total) {
        acc[idx] += mat[idx];
    }
}

void add_mat_gpu_compute_flat(const flat_mat& m1, const flat_mat& m2, flat_mat& result) {
    size_t total = (size_t)m1.rows * m1.cols;
    size_t size = total * sizeof(float);

    float *d_acc = g_d_acc;
    float *d_m2 = g_d_mat;
    bool local_alloc = false;

    if (!d_acc || g_alloc_elems < total) {
        if (cudaMalloc(&d_acc, size) != cudaSuccess) {
            throw std::runtime_error("CUDA malloc failed for accumulator");
        }
        if (cudaMalloc(&d_m2, size) != cudaSuccess) {
            throw std::runtime_error("CUDA malloc failed for matrix");
        }
        local_alloc = true;
    }

    result.rows = m1.rows;
    result.cols = m1.cols;
    result.data.resize(total);

    cudaMemcpy(d_acc, m1.data.data(), size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_m2, m2.data.data(), size, cudaMemcpyHostToDevice);

    int blockSize = 256;
    int gridSize = (int)((total + blockSize - 1) / blockSize);
    add_mat_1d_kernel<<<gridSize, blockSize>>>(d_acc, d_m2, total);
    cudaDeviceSynchronize();

    cudaMemcpy(result.data.data(), d_acc, size, cudaMemcpyDeviceToHost);

    if (local_alloc) {
        if (cudaFree(d_acc) != cudaSuccess) {
            throw std::runtime_error("CUDA free failed for accumulator");
        }
        if (cudaFree(d_m2) != cudaSuccess) {
            throw std::runtime_error("CUDA free failed for matrix");
        }
    }
}

void add_nmat_gpu_compute_flat(const std::vector<flat_mat>& mats, flat_mat& result) {
    int n_mats = (int)mats.size();
    if (n_mats == 0) return;

    int rows = mats[0].rows;
    int cols = mats[0].cols;
    size_t total = (size_t)rows * cols;
    size_t size = total * sizeof(float);

    float *d_acc = g_d_acc;
    float *d_mat = g_d_mat;
    bool local_alloc = false;

    if (!d_acc || g_alloc_elems < total) {
        if (cudaMalloc(&d_acc, size) != cudaSuccess) {
            throw std::runtime_error("CUDA malloc failed for accumulator");
        }
        if (cudaMalloc(&d_mat, size) != cudaSuccess) {
            throw std::runtime_error("CUDA malloc failed for matrix");
        }
        local_alloc = true;
    }

    result.rows = rows;
    result.cols = cols;
    result.data.resize(total);

    cudaMemcpy(d_acc, mats[0].data.data(), size, cudaMemcpyHostToDevice);

    int blockSize = 256;
    int gridSize = (int)((total + blockSize - 1) / blockSize);

    for (int k = 1; k < n_mats; k++) {
        cudaMemcpy(d_mat, mats[k].data.data(), size, cudaMemcpyHostToDevice);
        add_mat_1d_kernel<<<gridSize, blockSize>>>(d_acc, d_mat, total);
    }
    cudaDeviceSynchronize();

    cudaMemcpy(result.data.data(), d_acc, size, cudaMemcpyDeviceToHost);

    if (local_alloc) {
        if (cudaFree(d_acc) != cudaSuccess) {
            throw std::runtime_error("CUDA free failed for accumulator");
        }
        if (cudaFree(d_mat) != cudaSuccess) {
            throw std::runtime_error("CUDA free failed for matrix");
        }
    }
}

void init_gpu(size_t max_elements) {
    size_t size = max_elements * sizeof(float);
    if (g_alloc_elems >= max_elements) return;
    if (g_d_acc)  if (cudaFree(g_d_acc) != cudaSuccess) {
        throw std::runtime_error("CUDA free failed for accumulator");
    }
    if (g_d_mat)  if (cudaFree(g_d_mat) != cudaSuccess) {
        throw std::runtime_error("CUDA free failed for matrix");
    }

    if (cudaMalloc(&g_d_acc, size) != cudaSuccess) {
        throw std::runtime_error("CUDA malloc failed for accumulator");
    }
    if (cudaMalloc(&g_d_mat, size) != cudaSuccess) {
        throw std::runtime_error("CUDA malloc failed for matrix");
    }

    g_alloc_elems = max_elements;
}

void free_gpu() {
    if (g_d_acc) { if (cudaFree(g_d_acc) != cudaSuccess) {
        throw std::runtime_error("CUDA free failed for accumulator");
    } }
    if (g_d_mat) { if (cudaFree(g_d_mat) != cudaSuccess) {
        throw std::runtime_error("CUDA free failed for matrix");
    } }
    g_alloc_elems = 0;
}