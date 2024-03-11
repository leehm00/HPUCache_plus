#include <iostream>
#include <thread>
#include <chrono>
#include <string.h>
#include <sys/stat.h>
#include <sys/sysinfo.h>
#include <sys/time.h>
#include <unistd.h>

// get current process pid
inline int GetCurrentPid()
{
    return getpid();
}

// get specific process cpu occupation ratio by pid
// FIXME: can also get cpu and mem status from popen cmd
// the info line num in /proc/{pid}/status file
#define VMRSS_LINE 22
#define PROCESS_ITEM 14

static const char* get_items(const char* buffer, unsigned int item)
{
    // read from buffer by offset
    const char* p = buffer;

    int len = strlen(buffer);
    int count = 0;

    for (int i = 0; i < len; i++)
    {
        if (' ' == *p)
        {
            count++;
            if (count == item - 1)
            {
                p++;
                break;
            }
        }
        p++;
    }

    return p;
}

static inline unsigned long get_cpu_total_occupy()
{
    // get total cpu use time

    // different mode cpu occupy time
    unsigned long user_time;
    unsigned long nice_time;
    unsigned long system_time;
    unsigned long idle_time;

    FILE* fd;
    char buff[1024] = { 0 };

    fd = fopen("/proc/stat", "r");
    if (nullptr == fd)
        return 0;

    fgets(buff, sizeof(buff), fd);
    char name[64] = { 0 };
    sscanf(buff, "%s %ld %ld %ld %ld", name, &user_time, &nice_time, &system_time, &idle_time);
    fclose(fd);

    return (user_time + nice_time + system_time + idle_time);
}

static inline unsigned long get_cpu_proc_occupy(int pid)
{
    // get specific pid cpu use time
    unsigned int tmp_pid;
    unsigned long utime;  // user time
    unsigned long stime;  // kernel time
    unsigned long cutime; // all user time
    unsigned long cstime; // all dead time

    char file_name[64] = { 0 };
    FILE* fd;
    char line_buff[1024] = { 0 };
    sprintf(file_name, "/proc/%d/stat", pid);

    fd = fopen(file_name, "r");
    if (nullptr == fd)
        return 0;

    fgets(line_buff, sizeof(line_buff), fd);

    sscanf(line_buff, "%u", &tmp_pid);
    const char* q = get_items(line_buff, PROCESS_ITEM);
    sscanf(q, "%ld %ld %ld %ld", &utime, &stime, &cutime, &cstime);
    fclose(fd);

    return (utime + stime + cutime + cstime);
}

inline float GetCpuUsageRatio(int pid)
{
    unsigned long totalcputime1, totalcputime2;
    unsigned long procputime1, procputime2;

    totalcputime1 = get_cpu_total_occupy();
    procputime1 = get_cpu_proc_occupy(pid);

    // FIXME: the 200ms is a magic number, works well
    usleep(200000); // sleep 200ms to fetch two time point cpu usage snapshots sample for later calculation

    totalcputime2 = get_cpu_total_occupy();
    procputime2 = get_cpu_proc_occupy(pid);

    float pcpu = 0.0;
    if (0 != totalcputime2 - totalcputime1)
        pcpu = (procputime2 - procputime1) / float(totalcputime2 - totalcputime1); // float number

    int cpu_num = get_nprocs();
    pcpu *= cpu_num; // should multiply cpu num in multiple cpu machine

    return pcpu;
}

// get specific process physical memeory occupation size by pid (MB)
inline float GetMemoryUsage(int pid)
{
    char file_name[64] = { 0 };
    FILE* fd;
    char line_buff[512] = { 0 };
    sprintf(file_name, "/proc/%d/status", pid);

    fd = fopen(file_name, "r");
    if (nullptr == fd)
        return 0;

    char name[64];
    int vmrss = 0;
    for (int i = 0; i < VMRSS_LINE - 1; i++)
        fgets(line_buff, sizeof(line_buff), fd);

    fgets(line_buff, sizeof(line_buff), fd);
    sscanf(line_buff, "%s %d", name, &vmrss);
    fclose(fd);

    // cnvert VmRSS from KB to MB
    return vmrss / 1024.0;
}

int main()
{
    // launch some task to occupy cpu and memory
    for (int i = 0; i < 5; i++)
        std::thread([]
                {
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
                }).detach();

    int current_pid = GetCurrentPid(); // or you can set a outside program pid
    float cpu_usage_ratio = GetCpuUsageRatio(current_pid);
    float memory_usage = GetMemoryUsage(current_pid);

    while (true)
    {
        std::cout << "current pid: " << current_pid << std::endl;
        std::cout << "cpu usage ratio: " << cpu_usage_ratio * 100 << "%" << std::endl;
        std::cout << "memory usage: " << memory_usage << "MB" << std::endl;

        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    }

    return 0;
}
