#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

int main()
{
    int fbfd = 0;
    struct fb_var_screeninfo vinfo;
    struct fb_fix_screeninfo finfo;
    long int screensize = 0;
    char *fbp = 0;
    int x = 0, y = 0;
    long int location = 0;

    // Open the file for reading and writing
    fbfd = open("/dev/fb0", O_RDWR);

    // Get fixed screen information
    ioctl(fbfd, FBIOGET_FSCREENINFO, &finfo);

    // Get variable screen information
    ioctl(fbfd, FBIOGET_VSCREENINFO, &vinfo);

    printf("%dx%d, %dbpp\n", vinfo.xres, vinfo.yres, vinfo.bits_per_pixel);
    /* printf("%d", vinfo.xres); */

    // Figure out the size of the screen in bytes
    screensize = vinfo.xres * vinfo.yres * vinfo.bits_per_pixel / 8;

    printf("screensize: %d\n", screensize);
    printf("line_length: %d\n", finfo.line_length);

    /* // Map the device to memory */
    fbp = (char *)mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fbfd, 0);

    /* // Figure out where in memory to put the pixel */
    for (y = 100; y < 300; y++)
        for (x = 100; x < 300; x++) {

            location = (x+vinfo.xoffset) * (vinfo.bits_per_pixel/8) +
                       (y+vinfo.yoffset) * finfo.line_length;

            /* *(fbp + location) = 100;        // Some blue */
            /* *(fbp + location + 1) = 15+(x-100)/2;     // A little green */
            /* *(fbp + location + 2) = 200-(y-100)/5;    // A lot of red */
            /* *(fbp + location + 3) = 0;      // No transparency */
            *(fbp + location) = 255;        // Some blue
            *(fbp + location + 1) = 255;     // A little green
            *(fbp + location + 2) = 255;    // A lot of red
            *(fbp + location + 3) = 0;      // No transparency
        }

    /* munmap(fbp, screensize); */
    /* close(fbfd); */
    /* return 0; */
}
