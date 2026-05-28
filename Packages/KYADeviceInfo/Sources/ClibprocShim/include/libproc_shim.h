//
//  libproc_shim.h
//  ClibprocShim
//
//  C shim for libproc functions not directly callable from Swift.
//

#ifndef libproc_shim_h
#define libproc_shim_h

#include <libproc.h>

/// Returns the number of PIDs written into `buffer`.
/// `bufferSize` is the capacity of the buffer in bytes (not PID count).
/// Returns -1 on error.
int kya_proc_listallpids(pid_t *buffer, int bufferSize);

/// Writes the path for `pid` into `buffer`.
/// `bufferSize` is the capacity of the buffer in bytes.
/// Returns 0 on success, -1 on error.
int kya_proc_pidpath(pid_t pid, char *buffer, int bufferSize);

#endif /* libproc_shim_h */