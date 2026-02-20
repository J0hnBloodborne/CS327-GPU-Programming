#include <cstdio>
#include <stdexcept>
#include "../include/mat_ops.h"
#include "../include/mat_io.h"

int main(int argc, char** argv)
{
    if (argc < 2 || argc > 3) {
        fprintf(stderr, "Usage: %s <input file> [output file]\n", argv[0]);
        return 1;
    }

    const std::string outputPath = (argc == 3) ? argv[2] : "stdout";

    try {
        std::vector<flat_mat> inputMats = readMat(argv[1]);
        if (inputMats.size() < 2) {
            throw std::runtime_error("Input must contain at least two matrices");
        }

        flat_mat result;
        mulMat(inputMats[0], inputMats[1], result);
        writeMat(outputPath, result);
    } catch (const std::exception& ex) {
        fprintf(stderr, "Error: %s\n", ex.what());
        return 1;
    }

    return 0;
}
