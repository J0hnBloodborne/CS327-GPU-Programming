/*
![Figure 1: Denoising example (original image by Simpsons, CC BY-SA 3.0, <https://commons.wikimedia.org/w/index.php?curid=8904364>).](denoise.png)

The file [cuda-denoise.c](cuda-denoise.c) contains a serial
implementation of an _image denoising_ algorithm that (to some extent)
can be used to "cleanup" color images. The algorithm replaces the
color of each pixel with the _median_ of the four adjacent pixels plus
itself (_median-of-five_).  The median-of-five algorithm is applied
separately for each color channel (red, green, and blue).

This is particularly useful for removing "hot pixels", i.e., pixels
whose color is way off its intended value, for example due to problems
in the sensor used to acquire the image. However, depending on the
amount of noise, a single pass could be insufficient to remove every
hot pixel; see Figure 1.

The goal of this exercise is to parallelize the denoising algorithm on
the GPU using CUDA. You should launch as many CUDA threads as pixels
in the image, so that each thread is mapped onto a different pixel.

The input image is read from standard input in
[PPM](http://netpbm.sourceforge.net/doc/ppm.html) (Portable Pixmap)
format; the result is written to standard output in the same format.

To compile:

        nvcc cuda-denoise.cu -o cuda-denoise

To execute:

        ./cuda-denoise < input > output

Example:

        ./cuda-denoise < valve-noise.ppm > valve-denoised.ppm

## Files

- [cuda-denoise.cu](cuda-denoise.cu) [hpc.h](hpc.h)
- [valve-noise.ppm](valve-noise.ppm) (sample input)

 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <cuda_runtime.h>
#ifdef _WIN32
#include <io.h>
#include <fcntl.h>
#endif

#include "hpc.h"
typedef struct {
    int width;   /* Width of the image (in pixels) */
    int height;  /* Height of the image (in pixels) */
    int maxcol;  /* Largest color value (Used by the PPM read/write routines) */
    unsigned char *r, *g, *b; /* color channels (arrays of width x height elements each); each value must be less than or equal to maxcol */
} PPM_image;

/**
 * Read a PPM file from file `f`. This function is not very robust; it
 * may fail on perfectly legal PGM images, but works for the provided
 * cat.pgm file.
 */
void read_ppm( FILE *f, PPM_image* img )
{
    char buf[1024];
    const size_t BUFSIZE = sizeof(buf);
    char *s;
    int nread;

    assert(f != NULL);
    assert(img != NULL);

    /* Get the file type (must be "P6") */
    s = fgets(buf, BUFSIZE, f);
    if (0 != strcmp(s, "P6\n")) {
        fprintf(stderr, "FATAL: wrong file type %s\n", buf);
        exit(EXIT_FAILURE);
    }
    /* Get any comment and ignore it; does not work if there are
       leading spaces in the comment line */
    do {
        s = fgets(buf, BUFSIZE, f);
    } while (s[0] == '#');
    /* Get width, height */
    sscanf(s, "%d %d", &(img->width), &(img->height));
    /* get maxcol; must be less than or equal to 255 */
    s = fgets(buf, BUFSIZE, f);
    sscanf(s, "%d", &(img->maxcol));
    if ( img->maxcol > 255 ) {
        fprintf(stderr, "FATAL: maxcol=%d > 255\n", img->maxcol);
        exit(EXIT_FAILURE);
    }
    /* Get the binary data */
    img->r = (unsigned char*)malloc((img->width)*(img->height));
    assert(img->r != NULL);
    img->g = (unsigned char*)malloc((img->width)*(img->height));
    assert(img->g != NULL);
    img->b = (unsigned char*)malloc((img->width)*(img->height));
    assert(img->b != NULL);
    for (int k=0; k<(img->width)*(img->height); k++) {
        nread = fscanf(f, "%c%c%c", img->r + k, img->g + k, img->b + k);
        if (nread != 3) {
            fprintf(stderr, "FATAL: error reading pixel data\n");
            exit(EXIT_FAILURE);
        }
    }
}

/**
 * Write the image `img` to file `f`; is not NULL, use the string
 * `comment` as metadata.
 */
void write_ppm( FILE *f, const PPM_image* img, const char *comment )
{
    assert(f != NULL);
    assert(img != NULL);

    fprintf(f, "P6\n");
    fprintf(f, "# %s\n", comment != NULL ? comment : "");
    fprintf(f, "%d %d\n", img->width, img->height);
    fprintf(f, "%d\n", img->maxcol);
    for (int k=0; k<(img->width)*(img->height); k++) {
        fprintf(f, "%c%c%c", img->r[k], img->g[k], img->b[k]);
    }
}

/**
 * Free all memory used by the structure `img`
 */
void free_ppm( PPM_image* img )
{
    assert(img != NULL);
    free(img->r);
    free(img->g);
    free(img->b);
    img->r = img->g = img->b = NULL; /* not necessary */
    img->width = img->height = img->maxcol = -1;
}

#define BLKDIM 32

/**
 * Swap *a and *b if necessary so that, at the end, *a <= *b
 */
void compare_and_swap( unsigned char *a, unsigned char *b )
{
    if (*a > *b ) {
        unsigned char tmp = *a;
        *a = *b;
        *b = tmp;
    }
}

unsigned char *PTR(unsigned char *bmap, int width, int i, int j)
{
    return (bmap + i*width + j);
}

/**
 * Return the median of v[0..4]
 */
unsigned char median_of_five( unsigned char v[5] )
{
    /* We do a partial sort of v[5] using bubble sort until v[2] is
       correctly placed; this element is the median. (There are better
       ways to compute the median-of-five). */
    compare_and_swap( v+3, v+4 );
    compare_and_swap( v+2, v+3 );
    compare_and_swap( v+1, v+2 );
    compare_and_swap( v  , v+1 );
    compare_and_swap( v+3, v+4 );
    compare_and_swap( v+2, v+3 );
    compare_and_swap( v+1, v+2 );
    compare_and_swap( v+3, v+4 );
    compare_and_swap( v+2, v+3 );
    return v[2];
}

/**
 * Denoise a single color channel
 */
void denoise( unsigned char *bmap, int width, int height )
{
    unsigned char *out = (unsigned char*)malloc(width*height);
    unsigned char v[5];
    assert(out != NULL);

    memcpy(out, bmap, width*height);
    /* Note that the pixels on the border are left unchanged */
    for (int i=1; i<height - 1; i++) {
        for (int j=1; j<width - 1; j++) {
            v[0] = *PTR(bmap, width, i  , j  );
            v[1] = *PTR(bmap, width, i  , j-1);
            v[2] = *PTR(bmap, width, i  , j+1);
            v[3] = *PTR(bmap, width, i-1, j  );
            v[4] = *PTR(bmap, width, i+1, j  );

            *PTR(out, width, i, j) = median_of_five(v);
        }
    }
    memcpy(bmap, out, width*height);
    free(out);
}

__device__ void compare_and_swap_dev( unsigned char *a, unsigned char *b )
{
    if (*a > *b ) {
        unsigned char tmp = *a;
        *a = *b;
        *b = tmp;
    }
}

__device__ unsigned char median_of_five_dev( unsigned char v[5] )
{
    compare_and_swap_dev( v+3, v+4 );
    compare_and_swap_dev( v+2, v+3 );
    compare_and_swap_dev( v+1, v+2 );
    compare_and_swap_dev( v  , v+1 );
    compare_and_swap_dev( v+3, v+4 );
    compare_and_swap_dev( v+2, v+3 );
    compare_and_swap_dev( v+1, v+2 );
    compare_and_swap_dev( v+3, v+4 );
    compare_and_swap_dev( v+2, v+3 );
    return v[2];
}

__global__ void denoise_kernel( const unsigned char *in, unsigned char *out, int width, int height )
{
    const int i = blockIdx.y * blockDim.y + threadIdx.y;
    const int j = blockIdx.x * blockDim.x + threadIdx.x;

    if ( i >= height || j >= width ) {
        return;
    }

    if ( i == 0 || i == height - 1 || j == 0 || j == width - 1 ) {
        out[i*width + j] = in[i*width + j];
        return;
    }

    unsigned char v[5];
    v[0] = in[i*width + j];
    v[1] = in[i*width + (j-1)];
    v[2] = in[i*width + (j+1)];
    v[3] = in[(i-1)*width + j];
    v[4] = in[(i+1)*width + j];
    out[i*width + j] = median_of_five_dev(v);
}

void denoise_gpu( unsigned char *bmap, int width, int height )
{
    unsigned char *d_in = NULL;
    unsigned char *d_out = NULL;
    const int n = width * height;

    cudaSafeCall( cudaMalloc((void**)&d_in, n) );
    cudaSafeCall( cudaMalloc((void**)&d_out, n) );
    cudaSafeCall( cudaMemcpy(d_in, bmap, n, cudaMemcpyHostToDevice) );

    const dim3 block(16, 16);
    const dim3 grid((width + block.x - 1) / block.x, (height + block.y - 1) / block.y);
    denoise_kernel<<<grid, block>>>(d_in, d_out, width, height);
    cudaCheckError();

    cudaSafeCall( cudaMemcpy(bmap, d_out, n, cudaMemcpyDeviceToHost) );
    cudaSafeCall( cudaFree(d_out) );
    cudaSafeCall( cudaFree(d_in) );
}

int main( void )
{
#ifdef _WIN32
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
#endif

    PPM_image img, img_gpu;
    read_ppm(stdin, &img);

    img_gpu.width = img.width;
    img_gpu.height = img.height;
    img_gpu.maxcol = img.maxcol;
    img_gpu.r = (unsigned char*)malloc((img.width)*(img.height));
    img_gpu.g = (unsigned char*)malloc((img.width)*(img.height));
    img_gpu.b = (unsigned char*)malloc((img.width)*(img.height));
    assert(img_gpu.r != NULL);
    assert(img_gpu.g != NULL);
    assert(img_gpu.b != NULL);
    memcpy(img_gpu.r, img.r, (img.width)*(img.height));
    memcpy(img_gpu.g, img.g, (img.width)*(img.height));
    memcpy(img_gpu.b, img.b, (img.width)*(img.height));

    const double tstart_cpu = hpc_gettime();
    denoise(img.r, img.width, img.height);
    denoise(img.g, img.width, img.height);
    denoise(img.b, img.width, img.height);
    const double elapsed_cpu = hpc_gettime() - tstart_cpu;

    cudaSafeCall( cudaFree(0) );
    const double tstart_gpu = hpc_gettime();
    denoise_gpu(img_gpu.r, img_gpu.width, img_gpu.height);
    denoise_gpu(img_gpu.g, img_gpu.width, img_gpu.height);
    denoise_gpu(img_gpu.b, img_gpu.width, img_gpu.height);
    const double elapsed_gpu = hpc_gettime() - tstart_gpu;

    fprintf(stderr, "CPU Execution time %.3f\n", elapsed_cpu);
    fprintf(stderr, "GPU Execution time %.3f\n", elapsed_gpu);
    write_ppm(stdout, &img_gpu, "produced by cuda-denoise.cu");
    free_ppm(&img);
    free_ppm(&img_gpu);
    return EXIT_SUCCESS;
}
