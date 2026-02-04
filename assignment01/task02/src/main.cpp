#include <vector>
#include <iostream>
#include <stdexcept>
#include "../include/mat_ops.h"
using mat = std::vector<std::vector<int>>;

int main(int argc, char** argv)
{
    if (argc < 2 || argc > 3) {
        fprintf(stderr, "Usage: %s <input file> [output file]\n", argv[0]);
        return 1;
    }
    
    add_mat(argv[1], argc == 3 ? argv[2] : "output.txt");
}
