/******************************************************************************
 * @file
 * @brief Quick example of usage for my `printf` implemetation.
 * 
 * @copyright (C) Victor Baldin, 2024.
 *****************************************************************************/

extern "C" void miniprintf(const char* fmt, ...);

int main() {
    miniprintf("miniprintf message:\n");
    miniprintf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n",
               -1, -1, "love", 3802, 100, 33, 127,
                   -1, "love", 3802, 100, 33, 127);
    return 0;
}
