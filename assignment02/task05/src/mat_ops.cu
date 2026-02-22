#include "../include/mat_ops.cuh"
#define TILE_WIDTH 16

// 2 + 2 + 2 + 1 + 1 + 1 = 9 registers just for the kernel params
__global__ void matMulKernel(const double *M, const double *N, double *P, int M_rows, int M_cols, int N_cols) {
	int row = blockIdx.y * blockDim.y + threadIdx.y; // +1
	int col = blockIdx.x * blockDim.x + threadIdx.x; // +1

	if (row < M_rows && col < N_cols) {
		double value = 0; // +2
		for (int k = 0; k < M_cols; ++k) { // +1
			value += M[row * M_cols + k] * N[k * N_cols + col]; // +4 (2 for the loads, 1 for the multiply, 1 for the add)
		}
		P[row * N_cols + col] = value; // +1
	}
	// Total registers = 19 --> round it up to 20 at most (right?)
	// nvm just use occupancy function 👍
	// I was completely wrong, that shit had 40 registers
}

__global__ void matMulKernelTiled(const double *M, const double *N, double *P, int M_rows, int M_cols, int N_cols){
	int tx = threadIdx.x;
	int ty = threadIdx.y;
	int bx = blockIdx.x;
	int by = blockIdx.y;
	
	int row = by * blockDim.y + ty;
	int col = bx * blockDim.x + tx;

	__shared__ double M_tile[TILE_WIDTH][TILE_WIDTH];
	__shared__ double N_tile[TILE_WIDTH][TILE_WIDTH];
	double value = 0.0;
	for (int ph = 0; ph < (M_cols + TILE_WIDTH -1)/TILE_WIDTH; ++ph) {
		if (row < M_rows && ph * TILE_WIDTH + tx < M_cols) 
			M_tile[ty][tx] = M[row * M_cols + ph * TILE_WIDTH + tx];
		else 
			M_tile[ty][tx] = 0.0; // Avoid out-of-bounds access and long checking in the loop
		if (col < N_cols && ph * TILE_WIDTH + ty < M_cols) 
			N_tile[ty][tx] = N[(ph * TILE_WIDTH + ty) * N_cols + col];
		else 
			N_tile[ty][tx] = 0.0; // Avoid out-of-bounds access and long checking in the loop
		__syncthreads(); // All loaded
		for (int k = 0; k < TILE_WIDTH; ++k)
			value += M_tile[ty][k] * N_tile[k][tx];
		__syncthreads(); // Tile complete
	}
	if (row < M_rows && col < N_cols) // Still check for out-of-bounds
		P[row * N_cols + col] = value;
}

mat mulMatGPU(const mat& a, const mat& b) {
	if (a.cols != b.rows) {
		throw std::runtime_error("Matrix dimensions are incompatible for multiplication");
	}

	mat out(a.rows, b.cols);

	double *d_a, *d_b, *d_out;
	int size_a = a.rows * a.cols * sizeof(double);
	int size_b = b.rows * b.cols * sizeof(double);
	int size_out = out.rows * out.cols * sizeof(double);

	cudaMalloc((void**)&d_a, size_a);
	cudaMalloc((void**)&d_b, size_b);
	cudaMalloc((void**)&d_out, size_out);

	cudaMemcpy(d_a, a.data.data(), size_a, cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, b.data.data(), size_b, cudaMemcpyHostToDevice);

	int minGridSize;
	int blockSize1D;
	cudaOccupancyMaxPotentialBlockSize(&minGridSize, &blockSize1D, matMulKernel, 0, 0);

	int dim = (int)std::sqrt(blockSize1D); // Square block top 1 because we have 2D data
    dim3 blockDim(dim, dim);
	dim3 gridDim((out.cols + blockDim.x - 1) / blockDim.x,(out.rows + blockDim.y - 1) / blockDim.y);


	matMulKernel<<<gridDim, blockDim>>>(d_a, d_b, d_out, a.rows, a.cols, b.cols);

	cudaDeviceSynchronize();

	cudaMemcpy(out.data.data(), d_out, size_out, cudaMemcpyDeviceToHost);

	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_out);

	return out;
}

mat mulMatGPUTiled(const mat& a, const mat& b) {
	if (a.cols != b.rows) {
		throw std::runtime_error("Matrix dimensions are incompatible for multiplication");
	}

	mat out(a.rows, b.cols);

	double *d_a, *d_b, *d_out;
	int size_a = a.rows * a.cols * sizeof(double);
	int size_b = b.rows * b.cols * sizeof(double);
	int size_out = out.rows * out.cols * sizeof(double);

	cudaMalloc((void**)&d_a, size_a);
	cudaMalloc((void**)&d_b, size_b);
	cudaMalloc((void**)&d_out, size_out);

	cudaMemcpy(d_a, a.data.data(), size_a, cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, b.data.data(), size_b, cudaMemcpyHostToDevice);
	
	int minGridSize;
	int blockSize1D;
	cudaOccupancyMaxPotentialBlockSize(&minGridSize, &blockSize1D, matMulKernel, 0, 0);

	int dim = (int)std::sqrt(blockSize1D); // Square block top 1 because we have 2D data
    dim3 blockDim(dim, dim);
	dim3 gridDim((out.cols + blockDim.x - 1) / blockDim.x,(out.rows + blockDim.y - 1) / blockDim.y);
	
	matMulKernelTiled<<<gridDim, blockDim>>>(d_a, d_b, d_out, a.rows, a.cols, b.cols);

	cudaDeviceSynchronize();
	cudaMemcpy(out.data.data(), d_out, size_out, cudaMemcpyDeviceToHost);
	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_out);
	return out;
}