#include "../include/mat_ops.cuh"
#include "../include/mat_io.h"

__global__ void add_nmat_kernel(int *mats, int *res, int n_mats, int rows, int cols) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    if (row < rows && col < cols) {
        int sum = 0;
        for (int i = 0; i < n_mats; i++) sum+= mats[i*rows*cols + row*cols + col];
        res[row*cols + col] = sum;
    }
    return;
}

__global__ void add_mat_kernel(int *mat1, int *mat2, int *res, int rows, int cols) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    if (row < rows && col < cols) {
        res[row*cols + col] = mat1[row*cols + col] + mat2[row*cols + col];
    }
    return;
}

void add_nmat(std::string in, std::string out){
    std::vector<mat> m = readMat(in);
    if (m.size() < 2) {
        throw std::runtime_error("Input file must contain at least two matrices for addition.");
    }
    int rows = (int)m[0].size();
    int cols = (int)m[0][0].size();
    int total = rows * cols;

    std::vector<int> flatm ((int)m.size() * total);
    for (int k = 0; k < (int)m.size(); k++) {
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                flatm[k * total + i * cols + j] = m[k][i][j];
            }
        }
    }

    int *mats_d, *res_d;
    cudaMalloc((void**)&mats_d, flatm.size() * sizeof(int));
    cudaMalloc((void**)&res_d, total * sizeof(int));

    cudaMemcpy(mats_d, flatm.data(), flatm.size() * sizeof(int), cudaMemcpyHostToDevice);

    dim3 blockDims(16,16);
    dim3 gridDims((cols + blockDims.x -1)/blockDims.x, (rows + blockDims.y -1)/blockDims.y);
    add_nmat_kernel<<<gridDims, blockDims>>>(mats_d, res_d, (int)m.size(), rows, cols); 

    cudaMemcpy(flatm.data(), res_d, total * sizeof(int), cudaMemcpyDeviceToHost);
    mat result(rows,std::vector<int>(cols));
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            result[i][j] = flatm[i * cols + j];
        }
    }
    writeMat(out, result);
    cudaFree(mats_d);
    cudaFree(res_d);
    printf("Matrices added successfully.\n"); 
}

void add_mat(std::string in, std::string out){
    std::vector<mat> m = readMat(in);
    if (m.size() != 2) {
        throw std::runtime_error("Input file must contain exactly two matrices for addition.");
    }
    int rows = (int)m[0].size();
    int cols = (int)m[0][0].size();
    int total = rows * cols;

    std::vector<int> flatm1 (total);
    std::vector<int> flatm2 (total);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            flatm1[i * cols + j] = m[0][i][j];
            flatm2[i * cols + j] = m[1][i][j];
        }
    }
    int *mat1_d, *mat2_d, *res_d;
    cudaMalloc((void**)&mat1_d, flatm1.size()*sizeof(int));
    cudaMalloc((void**)&mat2_d, flatm2.size()*sizeof(int));
    cudaMalloc((void**)&res_d, flatm1.size()*sizeof(int));

    cudaMemcpy(mat1_d, flatm1.data(), flatm1.size() * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(mat2_d, flatm2.data(), flatm2.size() * sizeof(int), cudaMemcpyHostToDevice);
    dim3 blockDims(16,16);
    dim3 gridDims((cols + blockDims.x -1)/blockDims.x, (rows + blockDims.y -1)/blockDims.y);
    add_mat_kernel<<<gridDims, blockDims>>>(mat1_d, mat2_d,  res_d, rows, cols);
    cudaMemcpy(flatm1.data(), res_d, total * sizeof(int), cudaMemcpyDeviceToHost);
    mat result(rows,std::vector<int>(cols));
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            result[i][j] = flatm1[i * cols + j];
        }
    }
    writeMat(out, result);
    cudaFree(mat1_d);
    cudaFree(mat2_d);
    cudaFree(res_d);
    printf("Matrices added successfully.\n");
}