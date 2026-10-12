#include <sys/types.h> 
#include <sys/stat.h> 
#include <fcntl.h> 
#include <stdio.h> 
#include <unistd.h> 
#include <string.h>  

int main(int argc, char **argv) {     
    int fd;     
    char* filename = NULL;
    int val = 0;     

    if (argc != 2) {
        printf("usage: ./led_blink [device]\n");
        return -1;
    }

    filename = argv[1];     
    fd = open(filename, O_RDWR);  // 打开设备文件     
    if (fd < 0) {         
        printf("error, can't open %s\n", filename);         
        return -1;     
    }     

    printf("Start blinking the LED on %s. Press Ctrl+C to stop.\n", filename);

    while (1) {
        val = 0;  // 点亮 LED
        write(fd, &val, sizeof(val));
        usleep(500 * 1000);  // 延时 500ms

        val = 1;  // 熄灭 LED
        write(fd, &val, sizeof(val));
        usleep(500 * 1000);  // 延时 500ms
    }

    close(fd);     
    return 0; 
}
