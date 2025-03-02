#include <stdio.h>

/// In C, `main()` is the special function where the execution of a program begins.
/// It's the entry point – the operating system calls `main()` to start running y
/// our code.  Think of it as the main doorway into your program's logic.
int main(int argc, char *argv[], char *envp[]) {

    for (int i = 0; i < 10; i++) {
      // The printf utility formats and prints its arguments, after the first,
      // under control of the format.  The format is a character string which
      // contains three types of objects: plain characters, which are simply
      // copied to standard output, character escape sequences which are
      // converted and copied to the standard output, and format specifications,
      // each of which causes printing of the next successive argument.
      printf("%d\n", i);
    }

    // The function fflush() synchronizes the state of the given stream in light of buffered
    // I/O.  For output or update streams it writes all buffered data via the stream's
    // underlying write function.  For input streams it seeks to the current file position
    // indicator via the stream's underlying seek function.  The open status of the stream is
    // unaffected.

    fflush(NULL);

    // Single line comment
    return 0;
}
