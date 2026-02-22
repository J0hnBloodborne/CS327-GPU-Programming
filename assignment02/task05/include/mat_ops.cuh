#pragma once
#include "mat_io.h"

mat mulMatGPU(const mat& a, const mat& b);
mat mulMatGPUTiled(const mat& a, const mat& b);