static int _ConvertSMVer2Cores(int major, int minor)
{
    typedef struct {
        int SM;
        int Cores;
    } sSMtoCores;

    sSMtoCores nGpuArchCoresPerSM[] = {
        {0x20, 32}, {0x21, 48}, {0x30, 192}, {0x32, 192}, {0x35, 192}, {0x37, 192},
        {0x50, 128}, {0x52, 128}, {0x53, 128}, {0x60, 64},  {0x61, 128}, {0x62, 128},
        {0x70, 64},  {0x72, 64},  {0x75, 64},  {0x80, 64},  {0x86, 128}, {-1, -1}
    };

    int sm = (major << 4) + minor;
    int i = 0;
    while (nGpuArchCoresPerSM[i].SM != -1) {
        if (nGpuArchCoresPerSM[i].SM == sm) return nGpuArchCoresPerSM[i].Cores;
        ++i;
    }
    return -1;
}