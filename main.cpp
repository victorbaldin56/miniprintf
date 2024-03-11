/******************************************************************************
 * @file
 * @brief Quick example of usage for my `printf` implemetation.
 * 
 * @copyright (C) Victor Baldin, 2024.
 *****************************************************************************/

extern "C" int miniprintf(const char* fmt, ...);

int main() {
    miniprintf("This is  miniprintf\n, %s", "debugging");
    return 0;
}
