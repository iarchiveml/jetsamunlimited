#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <sys/proc.h>
#import "sys/libproc.h"
#import "sys/kern_memorystatus.h"
#include <sys/sysctl.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <process_name>\n", argv[0]);
        return 1;
    }

    const char *process_name = argv[1];
    pid_t target_pid = -1;

    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t size;
    if (sysctl(mib, 4, NULL, &size, NULL, 0) == -1) {
        perror("sysctl");
        return 1;
    }

    struct kinfo_proc *processes = malloc(size);
    if (processes == NULL) {
        perror("malloc");
        return 1;
    }

    if (sysctl(mib, 4, processes, &size, NULL, 0) == -1) {
        perror("sysctl");
        free(processes);
        return 1;
    }

    for (unsigned long i = 0; i < size / sizeof(struct kinfo_proc); i++) {
        if (strcmp(processes[i].kp_proc.p_comm, process_name) == 0) {
            target_pid = processes[i].kp_proc.p_pid;
            break;
        }
    }

    free(processes);

    if (target_pid == -1) {
        printf("Process '%s' not found\n", process_name);
        return 1;
    }

    int rc;
    memorystatus_priority_properties_t props = {JETSAM_PRIORITY_CRITICAL, 0};

    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_PRIORITY_PROPERTIES, target_pid, 0, &props, sizeof(props));
    if (rc < 0) {
        perror("memorystatus_control_1");
        exit(rc);
    }

    rc = memorystatus_control(MEMORYSTATUS_CMD_SET_PROCESS_IS_MANAGED, target_pid, 0, NULL, 0);
    if (rc < 0) {
        perror("memorystatus_control_3");
        exit(rc);
    }

    printf("Properties set successfully for process '%s' (PID: %d)\n", process_name, target_pid);
    return 0;
}
