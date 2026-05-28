#include "clog_shim.h"

os_log_t kya_log_create(const char *subsystem, const char *category)
{
    return os_log_create(subsystem, category);
}

void kya_log_debug(os_log_t log, const char *message)
{
    os_log_debug(log, "%{public}s", message);
}

void kya_log_info(os_log_t log, const char *message)
{
    os_log_info(log, "%{public}s", message);
}

void kya_log_error(os_log_t log, const char *message)
{
    os_log_error(log, "%{public}s", message);
}

void kya_log_fault(os_log_t log, const char *message)
{
    os_log_fault(log, "%{public}s", message);
}