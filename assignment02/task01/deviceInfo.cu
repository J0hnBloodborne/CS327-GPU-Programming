#include <stdio.h>
#include <cuda_runtime.h>
#include "sm2core.h"

int main()
{
    if(cudaGetDeviceCount(NULL) == 0) {
        printf("No CUDA-capable devices found.\n");
        return 1;
    }
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    printf("device Information:\n");

    printf("Device Name: %s\n", prop.name);
    printf("-This is the name of the device.\n\n");
    
    printf("Total Global Memory: %d bytes\n", (int)prop.totalGlobalMem);
    printf("-This is the total amount of global memory available on the device.\n\n");
    
    int clockRateKHz = 0;
    cudaDeviceGetAttribute(&clockRateKHz, cudaDevAttrClockRate, 0);
    printf("Clock Rate: %d MHz\n", clockRateKHz / 1000);
    printf("-This is the core clock rate of the device in megahertz.\n\n");

    printf("Memory Bus Width: %d bits\n", prop.memoryBusWidth);
    printf("-This is the width of the memory bus on the device in bits.\n\n");
    
    int memoryClockRateKHz = 0;
    cudaDeviceGetAttribute(&memoryClockRateKHz, cudaDevAttrMemoryClockRate, 0);
    printf("Memory Clock Rate: %d kHz\n", memoryClockRateKHz);
    printf("-This is the memory clock rate of the device in kilohertz.\n\n");

    printf("Max Global Memory Bandwidth: %d bytes/s\n", (int)memoryClockRateKHz * 1000 * (prop.memoryBusWidth / 8) * 2);
    printf("-This is the maximum global memory bandwidth of the device in bytes per second, calculated as (memory clock rate in Hz) * (memory bus width / 8) * 2 (for DDR memory).\n\n");
    
    printf("Compute Capability: %d.%d\n", prop.major, prop.minor);
    printf("-This is the compute capability of the device, represented as major and minor version numbers.\n\n");


    int coresPerSM = _ConvertSMVer2Cores(prop.major, prop.minor);
    int totalCores = prop.multiProcessorCount * coresPerSM;
    int flopsPerCore = 2;
    double peakGFLOPS = ((double)totalCores * (double)clockRateKHz * (double)flopsPerCore) / 1000000.0;

    printf("Peak compute performance: %.2lf GFLOPS\n", peakGFLOPS);
    printf("-Peak FP32 performance estimated as (cores) * (clock kHz) * (FLOPs per core per cycle) / 1,000,000.\n\n");

    printf("Shared Memory Per Block: %d bytes\n", (int)prop.sharedMemPerBlock);
    printf("-This is the amount of shared memory available per block on the device.\n\n");
    
    printf("Registers Per Block: %d\n", prop.regsPerBlock);
    printf("-This is the number of 32-bit registers available per block on the device.\n\n");
    
    printf("Warp Size: %d threads\n", prop.warpSize);
    printf("-This is the number of threads in a warp on the device.\n\n");
    
    printf("Max Threads Per Block: %d\n", prop.maxThreadsPerBlock);
    printf("-This is the maximum number of threads that can be launched in a single block on the device.\n\n");
    
    printf("Max Threads Dim: %d x %d x %d\n", prop.maxThreadsDim[0], prop.maxThreadsDim[1], prop.maxThreadsDim[2]);
    printf("-This is the maximum size of each dimension of a block on the device.\n\n");
    printf("Max Grid Size: %d x %d x %d\n", prop.maxGridSize[0], prop.maxGridSize[1], prop.maxGridSize[2]);
    printf("-This is the maximum size of each dimension of a grid on the device.\n\n");
    
    printf("Total Constant Memory: %d bytes\n", (int)prop.totalConstMem);
    printf("-This is the total amount of constant memory available on the device.\n\n");
    
    printf("Multi Processor Count: %d\n", prop.multiProcessorCount);
    printf("-This is the number of multiprocessors on the device.\n\n");

    printf("CUDA Cores: %d\n", totalCores);
    printf("-This is the total number of CUDA cores on the device (SMs * cores per SM).\n\n");
}