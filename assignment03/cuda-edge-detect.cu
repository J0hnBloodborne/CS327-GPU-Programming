/*
![Result of the Sobel operator](edge-detect.png)

The [Sobel operator](https://en.wikipedia.org/wiki/Sobel_operator) is
used to detect the edges on an grayscale image. The idea is to compute
the gradient of color change across each pixel; those pixels for which
the gradient exceeds a user-defined threshold are considered to be
part of an edge. Computation of the gradient involves the application
of a $3 \times 3$ stencil to the input image.

The program reads an input image fro standard input in
[PGM](https://en.wikipedia.org/wiki/Netpbm#PGM_example) (_Portable
Graymap_) format and produces a B/W image to standard output. The user
can specify an optional threshold on the command line.

The goal of this exercise is to parallelize the computation of the
Sobel operator using CUDA; this can be achieved by writing a kernel
that computes the edge at each pixel, and invoke the kernel from the
`edge_detect()` function.

To compile:

        nvcc cuda-edge-detect.cu -o cuda-edge-detect

To execute:

        ./cuda-edge-detect [threshold] < input > output

Example:

        ./cuda-edge-detect < BWstop-sign.pgm > BWstop-sign-edges.pgm

## Files

- [cuda-edge-detect.cu](cuda-edge-detect.cu) [hpc.h](hpc.h)
- [BWstop-sign.pgm](BWstop-sign.pgm)

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
#include <string.h>

typedef struct {
    int width;   /* Width of the image (in pixels) */
    int height;  /* Height of the image (in pixels) */
    int maxgrey; /* Don't care (used only by the PGM read/write routines) */
    unsigned char *bmap; /* buffer of width*height bytes; each element represents the gray level of a pixel (0-255) */
} PGM_image;

const unsigned char WHITE = 255;
const unsigned char BLACK = 0;

/**
 * Initialize a PGM_image object: allocate space for a bitmap of size
 * `width` x `height`, and set all pixels to color `col`
 */
void init_pgm( PGM_image *img, int width, int height, unsigned char col )
{
    int i, j;

    assert(img != NULL);

    img->width = width;
    img->height = height;
    img->maxgrey = 255;
    img->bmap = (unsigned char*)malloc(width*height);
    assert(img->bmap != NULL);
    for (i=0; i<height; i++) {
        for (j=0; j<width; j++) {
            img->bmap[i*width + j] = col;
        }
    }
}

/**
 * Read a PGM file from file `f`. Warning: this function is not
 * robust: it may fail on legal PGM images, and may crash on invalid
 * files since no proper error checking is done.
 */
void read_pgm( FILE *f, PGM_image* img )
{
    char buf[1024];
    const size_t BUFSIZE = sizeof(buf);
    char *s;
    int nread;

    assert(f != NULL);
    assert(img != NULL);

    /* Get the file type (must be "P5") */
    s = fgets(buf, BUFSIZE, f);
    if (0 != strcmp(s, "P5\n")) {
        fprintf(stderr, "Wrong file type %s\n", buf);
        exit(EXIT_FAILURE);
    }
    /* Get any comment and ignore it; does not work if there are
       leading spaces in the comment line */
    do {
        s = fgets(buf, BUFSIZE, f);
    } while (s[0] == '#');
    /* Get width, height */
    sscanf(s, "%d %d", &(img->width), &(img->height));
    /* get maxgrey; must be less than or equal to 255 */
    s = fgets(buf, BUFSIZE, f);
    sscanf(s, "%d", &(img->maxgrey));
    if ( img->maxgrey > 255 ) {
        fprintf(stderr, "FATAL: maxgray=%d > 255\n", img->maxgrey);
        exit(EXIT_FAILURE);
    }
#if _XOPEN_SOURCE < 600
    img->bmap = (unsigned char*)malloc((img->width)*(img->height)*sizeof(unsigned char));
#else
    /* The pointer img->bmap must be properly aligned to allow aligned
       SIMD load/stores to work. */
    int ret = posix_memalign((void**)&(img->bmap), __BIGGEST_ALIGNMENT__, (img->width)*(img->height));
    assert( 0 == ret );
#endif
    assert(img->bmap != NULL);
    /* Get the binary data from the file */
    nread = fread(img->bmap, 1, (img->width)*(img->height), f);
    if ( (img->width)*(img->height) != nread ) {
        fprintf(stderr, "FATAL: error reading input: expecting %d bytes, got %d\n", (img->width)*(img->height), nread);
        exit(EXIT_FAILURE);
    }
}

/**
 * Write the image `img` to file `f`; if not NULL, use the string
 * `comment` as metadata.
 */
void write_pgm( FILE *f, const PGM_image* img, const char *comment )
{
    assert(f != NULL);
    assert(img != NULL);

    fprintf(f, "P5\n");
    fprintf(f, "# %s\n", comment != NULL ? comment : "");
    fprintf(f, "%d %d\n", img->width, img->height);
    fprintf(f, "%d\n", img->maxgrey);
    fwrite(img->bmap, 1, (img->width)*(img->height), f);
}

/**
 * Free the bitmap associated with image `img`; note that the
 * structure pointed to by `img` is NOT deallocated; only `img->bmap`
 * is.
 */
void free_pgm( PGM_image *img )
{
    assert(img != NULL);
    free(img->bmap);
    img->bmap = NULL; /* not necessary */
    img->width = img->height = img->maxgrey = -1;
}

int IDX(int i, int j, int width)
{
    return (i*width + j);
}


/**
 * Edge detection using the Sobel operator
 */
void edge_detect( const PGM_image* in, PGM_image* edges, int threshold )
{
    const int width = in->width;
    const int height = in->height;
    for (int i = 1; i < height-1; i++) {
        for (int j = 1; j < width-1; j++)  {
            /* Compute the gradients Gx and Gy along the x and y
               dimensions */
            const int Gx =
                in->bmap[IDX(i-1, j-1, width)] - in->bmap[IDX(i-1, j+1, width)]
                + 2*in->bmap[IDX(i, j-1, width)] - 2*in->bmap[IDX(i, j+1, width)]
                + in->bmap[IDX(i+1, j-1, width)] - in->bmap[IDX(i+1, j+1, width)];
            const int Gy =
                in->bmap[IDX(i-1, j-1, width)] + 2*in->bmap[IDX(i-1, j, width)] + in->bmap[IDX(i-1, j+1, width)]
                - in->bmap[IDX(i+1, j-1, width)] - 2*in->bmap[IDX(i+1, j, width)] - in->bmap[IDX(i+1, j+1, width)];
            const int magnitude = Gx * Gx + Gy * Gy;
            if  (magnitude > threshold*threshold)
                edges->bmap[IDX(i, j, width)] = WHITE;
            else
                edges->bmap[IDX(i, j, width)] = BLACK;
        }
    }
}

__global__ void edge_detect_kernel( const unsigned char *in, unsigned char *out, int width, int height, int threshold )
{
    const int i = blockIdx.y * blockDim.y + threadIdx.y;
    const int j = blockIdx.x * blockDim.x + threadIdx.x;
    const int idx = i*width + j;

    if ( i >= height || j >= width ) {
        return;
    }

    if ( i == 0 || i == height-1 || j == 0 || j == width-1 ) {
        out[idx] = WHITE;
        return;
    }

    const int Gx =
        in[(i-1)*width + (j-1)] - in[(i-1)*width + (j+1)]
        + 2*in[i*width + (j-1)] - 2*in[i*width + (j+1)]
        + in[(i+1)*width + (j-1)] - in[(i+1)*width + (j+1)];
    const int Gy =
        in[(i-1)*width + (j-1)] + 2*in[(i-1)*width + j] + in[(i-1)*width + (j+1)]
        - in[(i+1)*width + (j-1)] - 2*in[(i+1)*width + j] - in[(i+1)*width + (j+1)];
    const int magnitude = Gx * Gx + Gy * Gy;
    if  (magnitude > threshold*threshold)
        out[idx] = WHITE;
    else
        out[idx] = BLACK;
}

void edge_detect_gpu( const PGM_image* in, PGM_image* edges, int threshold )
{
    unsigned char *d_in = NULL;
    unsigned char *d_out = NULL;
    const int n = in->width * in->height;

    cudaSafeCall( cudaMalloc((void**)&d_in, n) );
    cudaSafeCall( cudaMalloc((void**)&d_out, n) );
    cudaSafeCall( cudaMemcpy(d_in, in->bmap, n, cudaMemcpyHostToDevice) );

    const dim3 block(16, 16);
    const dim3 grid((in->width + block.x - 1) / block.x, (in->height + block.y - 1) / block.y);
    edge_detect_kernel<<<grid, block>>>(d_in, d_out, in->width, in->height, threshold);
    cudaCheckError();

    cudaSafeCall( cudaMemcpy(edges->bmap, d_out, n, cudaMemcpyDeviceToHost) );
    cudaSafeCall( cudaFree(d_out) );
    cudaSafeCall( cudaFree(d_in) );
}

int main( int argc, char* argv[] )
{
    PGM_image bmap, out, out_gpu;
    int threshold = 70;

#ifdef _WIN32
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
#endif

    if ( argc > 2 ) {
        fprintf(stderr, "Usage: %s [threshold] < in.pgm > out.pgm\n", argv[0]);
        return EXIT_FAILURE;
    }
    if ( argc > 1 ) {
        threshold = atoi(argv[1]);
    }
    read_pgm(stdin, &bmap);
    init_pgm(&out, bmap.width, bmap.height, WHITE);
    init_pgm(&out_gpu, bmap.width, bmap.height, WHITE);

    const double tstart_cpu = hpc_gettime();
    edge_detect(&bmap, &out, threshold);
    const double elapsed_cpu = hpc_gettime() - tstart_cpu;

    cudaSafeCall( cudaFree(0) );
    const double tstart_gpu = hpc_gettime();
    edge_detect_gpu(&bmap, &out_gpu, threshold);
    const double elapsed_gpu = hpc_gettime() - tstart_gpu;

    fprintf(stderr, "CPU Execution time %.3f\n", elapsed_cpu);
    fprintf(stderr, "GPU Execution time %.3f\n", elapsed_gpu);
    write_pgm(stdout, &out_gpu, "produced by opencl-edge-detect.c");
    free_pgm(&bmap);
    free_pgm(&out);
    free_pgm(&out_gpu);
    return EXIT_SUCCESS;
}
