//
//  libproc_shim.c
//  ClibprocShim
//
//  C shim for libproc functions not directly callable from Swift.
//

#include "libproc_shim.h"

int kya_proc_listallpids(pid_t *buffer, int bufferSize)
{
    return proc_listallpids(buffer, bufferSize);
}

int kya_proc_pidpath(pid_t pid, char *buffer, int bufferSize)
{
    return proc_pidpath(pid, buffer, bufferSize);
}