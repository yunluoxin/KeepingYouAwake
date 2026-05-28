#ifndef CLOG_SHIM_H
#define CLOG_SHIM_H
#include <os/log.h>

os_log_t kya_log_create(const char *subsystem, const char *category);
void kya_log_debug(os_log_t log, const char *message);
void kya_log_info(os_log_t log, const char *message);
void kya_log_error(os_log_t log, const char *message);
void kya_log_fault(os_log_t log, const char *message);

#endif