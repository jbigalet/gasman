#include <stdio.h>
#include <termios.h>            //termios, TCSANOW, ECHO, ICANON
#include <unistd.h>     //STDIN_FILENO
#include <sys/select.h>
#include <string.h>

int main(void){
    static struct termios state;
    tcgetattr(STDIN_FILENO, &state);
    state.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &state);

    printf("%d\n", sizeof(state.c_line));
    printf("%d\n", NCCS);

    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 0;

    sleep(1);

    char s_rd[128];
    memset(&s_rd, 0, 128);
    s_rd[0] = 1;

    int r = select(1, &s_rd, NULL, NULL, &tv);
    printf("%d\n", r);

    /* if(r == 1){ */
    /*   char buf[100]; */
    /*   memset(&buf, 0, 100); */
    /*   read(0, buf, 100); */

    /*   for(int i=0 ; i<100 ; i++){ */
    /*     if(buf[i] == 0) */
    /*       break; */
    /*     printf("%d => %d\n", i, buf[i]); */
    /*   } */
    /* } */

    return 0;
}
