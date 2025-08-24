#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'; PURPLE='\033[0;35m'

echo -e "${BOLD}${CYAN}🖥️  macOS Health Check Report${NC}"
echo "Generated: $(date)"
echo "========================================="

# 1. System Overview with Load Averages
echo -e "${BOLD}${BLUE}📊 System Overview${NC}"
echo "macOS: $(sw_vers -productVersion)"
UPTIME_STR=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
echo "Uptime: $UPTIME_STR"

# Load average analysis with context
LOAD_RAW=$(uptime | awk -F'load averages:' '{print $2}')
LOAD_1M=$(echo $LOAD_RAW | awk '{print $1}')
LOAD_5M=$(echo $LOAD_RAW | awk '{print $2}')
LOAD_15M=$(echo $LOAD_RAW | awk '{print $3}')
CPU_COUNT=$(sysctl -n hw.ncpu)

echo "Load Averages: $LOAD_1M (1m) $LOAD_5M (5m) $LOAD_15M (15m)"
echo "CPU Cores: $CPU_COUNT"

# Load analysis with recommendations
LOAD_PCT=$(echo "scale=0; $LOAD_1M * 100 / $CPU_COUNT" | bc -l 2>/dev/null || echo "0")
if [[ $LOAD_PCT -gt 100 ]]; then
    echo -e "${RED}🚨 System Load: ${LOAD_PCT}% (OVERLOADED - System struggling)${NC}"
    echo -e "${YELLOW}   💡 Action: Identify heavy processes, consider restart if persistent${NC}"
elif [[ $LOAD_PCT -gt 80 ]]; then
    echo -e "${YELLOW}⚠️  System Load: ${LOAD_PCT}% (HIGH - May affect performance)${NC}"
    echo -e "${YELLOW}   💡 Action: Monitor heavy processes, avoid intensive tasks${NC}"
elif [[ $LOAD_PCT -gt 60 ]]; then
    echo -e "${YELLOW}📊 System Load: ${LOAD_PCT}% (ELEVATED - Normal for active use)${NC}"
else
    echo -e "${GREEN}✅ System Load: ${LOAD_PCT}% (HEALTHY)${NC}"
fi

echo "RAM: $(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024) " GB"}')"

# Memory pressure check with detailed analysis
if command -v memory_pressure >/dev/null 2>&1; then
    MEMORY_PRESSURE=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//' || echo "50")
    if [[ $MEMORY_PRESSURE -lt 15 ]]; then
        echo -e "${RED}🚨 Memory Pressure: ${MEMORY_PRESSURE}% free (CRITICAL)${NC}"
        echo -e "${RED}   💡 Action: Close apps, restart if needed, check for memory leaks${NC}"
    elif [[ $MEMORY_PRESSURE -lt 25 ]]; then
        echo -e "${YELLOW}⚠️  Memory Pressure: ${MEMORY_PRESSURE}% free (LOW)${NC}"
        echo -e "${YELLOW}   💡 Action: Close unnecessary apps, avoid memory-intensive tasks${NC}"
    elif [[ $MEMORY_PRESSURE -lt 40 ]]; then
        echo -e "${YELLOW}📊 Memory Pressure: ${MEMORY_PRESSURE}% free (MEDIUM)${NC}"
        echo -e "${BLUE}   💡 Tip: Monitor memory usage, normal for active use${NC}"
    else
        echo -e "${GREEN}✅ Memory Pressure: ${MEMORY_PRESSURE}% free (GOOD)${NC}"
    fi
else
    echo "Memory Pressure: Unable to check (memory_pressure not available)"
fi

DISK_INFO=$(df -h / | awk 'NR==2 {print $4 " free of " $2 " (" $5 " used)"}')
DISK_PCT=$(df -h / | awk 'NR==2 {print substr($5, 1, length($5)-1)}')
echo -n "Disk: $DISK_INFO"
if [[ $DISK_PCT -gt 90 ]]; then
    echo -e " ${RED}🚨 CRITICAL${NC}"
    echo -e "${RED}   💡 Action: Free up space immediately, empty trash, clear caches${NC}"
elif [[ $DISK_PCT -gt 80 ]]; then
    echo -e " ${YELLOW}⚠️  LOW${NC}"
    echo -e "${YELLOW}   💡 Action: Clean up files, check Downloads folder${NC}"
else
    echo -e " ${GREEN}✅${NC}"
fi
echo

# 2. Real-time Process Snapshot with better sampling
echo -e "${BOLD}${YELLOW}🔥 CPU Usage Analysis (5-second average)${NC}"
echo "Sampling processes for better accuracy..."
ps -Ao pid,user,%cpu,%mem,comm -r > /tmp/ps_sample.txt
sleep 5
ps -Ao pid,user,%cpu,%mem,comm -r > /tmp/ps_current.txt

echo "  PID USER              %CPU %MEM PROCESS"
head -n 11 /tmp/ps_current.txt | tail -n +2

# Analyze top CPU consumers
echo -e "\n${PURPLE}🔍 CPU Analysis:${NC}"
TOP_CPU=$(head -n 2 /tmp/ps_current.txt | tail -n 1 | awk '{print $3}')
TOP_PROCESS=$(head -n 2 /tmp/ps_current.txt | tail -n 1 | awk '{print $5}' | sed 's#.*/##')

if (( $(echo "$TOP_CPU > 80" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "${RED}🚨 Highest CPU: $TOP_PROCESS ($TOP_CPU%) - EXTREMELY HIGH${NC}"
    echo -e "${RED}   💡 Action: Investigate this process, may need to quit/restart${NC}"
elif (( $(echo "$TOP_CPU > 50" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "${YELLOW}⚠️  Highest CPU: $TOP_PROCESS ($TOP_CPU%) - HIGH${NC}"
    echo -e "${YELLOW}   💡 Action: Monitor this process, check what it's doing${NC}"
elif (( $(echo "$TOP_CPU > 20" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "${BLUE}📊 Highest CPU: $TOP_PROCESS ($TOP_CPU%) - ELEVATED${NC}"
    echo -e "${BLUE}   💡 Info: Normal for active applications${NC}"
else
    echo -e "${GREEN}✅ Highest CPU: $TOP_PROCESS ($TOP_CPU%) - NORMAL${NC}"
fi

rm -f /tmp/ps_sample.txt /tmp/ps_current.txt
echo

# 3. Spotlight/Indexing Analysis
echo -e "${BOLD}${PURPLE}🔍 Spotlight Indexing Status${NC}"
SPOTLIGHT_PROCESSES=$(ps -Ao pid,%cpu,%mem,comm | grep -E "(mds|mdworker|mdsync)" | grep -v grep)

if [[ -n "$SPOTLIGHT_PROCESSES" ]]; then
    echo "Active Spotlight processes:"
    echo "$SPOTLIGHT_PROCESSES" | while IFS= read -r line; do
        CPU=$(echo "$line" | awk '{print $2}')
        PROCESS=$(echo "$line" | awk '{print $4}' | sed 's#.*/##')
        
        if (( $(echo "$CPU > 50" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${RED}  🔥 $PROCESS: ${CPU}% CPU (INTENSIVE INDEXING)${NC}"
        elif (( $(echo "$CPU > 20" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${YELLOW}  ⚡ $PROCESS: ${CPU}% CPU (ACTIVE INDEXING)${NC}"
        else
            echo -e "${GREEN}  ✅ $PROCESS: ${CPU}% CPU (LIGHT INDEXING)${NC}"
        fi
    done
    
    # Indexing recommendations
    TOTAL_SPOTLIGHT_CPU=$(echo "$SPOTLIGHT_PROCESSES" | awk '{sum += $2} END {print sum}')
    if (( $(echo "$TOTAL_SPOTLIGHT_CPU > 100" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${BLUE}💡 Spotlight is rebuilding index (high CPU is temporary)${NC}"
        echo -e "${BLUE}   ⏰ Expected: 30-60 minutes for completion${NC}"
        echo -e "${BLUE}   🌡️  System may be warm during this process${NC}"
        echo -e "${BLUE}   ❌ Don't interrupt: Let indexing complete naturally${NC}"
    elif (( $(echo "$TOTAL_SPOTLIGHT_CPU > 50" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${YELLOW}💡 Active indexing in progress (normal after new files/apps)${NC}"
        echo -e "${BLUE}   ⏰ Should complete within 15-30 minutes${NC}"
    fi
else
    echo -e "${GREEN}✅ No active Spotlight indexing${NC}"
fi

# Check indexing status
INDEXING_STATUS=$(sudo mdutil -a -s 2>/dev/null | grep -c "enabled" || echo "0")
if [[ $INDEXING_STATUS -gt 0 ]]; then
    echo -e "${GREEN}📍 Spotlight indexing: Enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Spotlight indexing: Disabled${NC}"
    echo -e "${BLUE}   💡 Info: Search functionality limited${NC}"
fi
echo

# 4. System Process Health Check
echo -e "${BOLD}${RED}🔍 System Process Analysis${NC}"
echo "Critical system processes status:"

SYSTEM_PROCS=("launchd" "kernel_task" "logd" "WindowServer" "loginwindow" "launchservicesd" "runningboardd")
SYSTEM_ISSUES=0

for proc in "${SYSTEM_PROCS[@]}"; do
    CPU=$(ps -Ao %cpu,comm | grep -i "$proc" | head -n1 | awk '{print $1}' || echo "0")
    if [[ -n "$CPU" && "$CPU" != "0" ]]; then
        if (( $(echo "$CPU > 20" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${RED}🚨 $proc: ${CPU}% CPU (CRITICAL - System instability)${NC}"
            echo -e "${RED}   💡 Action: System restart recommended${NC}"
            SYSTEM_ISSUES=$((SYSTEM_ISSUES + 1))
        elif (( $(echo "$CPU > 10" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${YELLOW}⚠️  $proc: ${CPU}% CPU (ELEVATED - Monitor closely)${NC}"
            echo -e "${YELLOW}   💡 Action: Check system logs, consider restart if persistent${NC}"
            SYSTEM_ISSUES=$((SYSTEM_ISSUES + 1))
        elif (( $(echo "$CPU > 5" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${YELLOW}📊 $proc: ${CPU}% CPU (ACTIVE - Likely normal)${NC}"
        else
            echo -e "${GREEN}✅ $proc: ${CPU}% CPU (NORMAL)${NC}"
        fi
    else
        echo -e "${BLUE}ℹ️  $proc: Not running or not found${NC}"
    fi
done

if [[ $SYSTEM_ISSUES -gt 2 ]]; then
    echo -e "${RED}\n🚨 MULTIPLE SYSTEM ISSUES DETECTED${NC}"
    echo -e "${RED}💡 Recommended Action: System restart to reset daemons${NC}"
elif [[ $SYSTEM_ISSUES -gt 0 ]]; then
    echo -e "${YELLOW}\n⚠️  System processes elevated - monitor closely${NC}"
else
    echo -e "${GREEN}\n✅ All system processes healthy${NC}"
fi
echo

# 5. Memory Analysis with actionable insights
echo -e "${BOLD}${YELLOW}💾 Memory Usage Analysis${NC}"
echo "Top memory consumers:"
ps -Ao pid,user,%mem,rss,comm -m | head -n 6 | awk 'NR>1 {
    rss_mb = int($4/1024)
    printf "  %-6s %-10s %5s%% %6s MB %s\n", $1, $2, $3, rss_mb, $5
}'

# Check for memory hogs
MEMORY_HOGS=$(ps -Ao pid,user,%mem,rss,comm | awk '$4 > 1048576 {print "  PID " $1 ": " int($4/1024) "MB - " $5}')
if [[ -n "$MEMORY_HOGS" ]]; then
    echo -e "\n${YELLOW}🐘 Processes using >1GB RAM:${NC}"
    echo "$MEMORY_HOGS"
    echo -e "${YELLOW}💡 Action: Check if these memory levels are normal for these apps${NC}"
else
    echo -e "\n${GREEN}✅ No excessive memory usage detected${NC}"
fi
echo

# 6. Enhanced Problem Detection
echo -e "${BOLD}${RED}🚨 System Issues Detection${NC}"

ISSUES_FOUND=0

# Check for runaway processes
RUNAWAY_PROCS=$(ps -Ao pid,user,%cpu,comm | awk '$3 > 50 {print "  PID " $1 " (" $2 "): " $3 "% - " $4}')
if [[ -n "$RUNAWAY_PROCS" ]]; then
    echo -e "${RED}🔥 High CPU processes (>50%):${NC}"
    echo "$RUNAWAY_PROCS"
    echo -e "${RED}💡 Action: Identify what these processes are doing, quit if necessary${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check for zombie processes
ZOMBIES=$(ps -axo pid,stat,comm | awk '$2 ~ /Z/ {print "  PID " $1 ": " $3}')
if [[ -n "$ZOMBIES" ]]; then
    echo -e "${RED}💀 Zombie processes found:${NC}"
    echo "$ZOMBIES"
    echo -e "${RED}💡 Action: These processes are stuck, restart may be needed${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check for process explosion
PROC_EXPLOSION=$(ps -Ao comm | sed 's#.*/##' | sort | uniq -c | awk '$1 > 15 {print "  " $2 ": " $1 " processes"}')
if [[ -n "$PROC_EXPLOSION" ]]; then
    echo -e "${YELLOW}📊 Apps with many processes (>15):${NC}"
    echo "$PROC_EXPLOSION"
    echo -e "${YELLOW}💡 Info: May be normal for some apps, but monitor for issues${NC}"
fi

# Overall system health summary
if [[ $ISSUES_FOUND -eq 0 ]]; then
    echo -e "${GREEN}✅ No critical issues detected${NC}"
else
    echo -e "${YELLOW}⚠️  $ISSUES_FOUND issue(s) detected - review recommendations above${NC}"
fi
echo

# 7. System Activity Context
echo -e "${BOLD}${BLUE}📈 System Activity Context${NC}"

# Check if Spotlight is indexing
if pgrep -q mds >/dev/null 2>&1; then
    echo -e "${BLUE}📍 Spotlight: Active (may cause temporary high CPU/disk usage)${NC}"
else
    echo -e "${GREEN}📍 Spotlight: Inactive${NC}"
fi

# Check backup activity
if pgrep -q backupd >/dev/null 2>&1; then
    echo -e "${BLUE}💾 Time Machine: Running (may affect performance temporarily)${NC}"
else
    echo -e "${GREEN}💾 Time Machine: Not running${NC}"
fi

# Check for software updates
if command -v softwareupdate >/dev/null 2>&1; then
    UPDATES=$(softwareupdate -l 2>/dev/null | grep -c "recommended" || echo "0")
    if [[ $UPDATES -gt 0 ]]; then
        echo -e "${YELLOW}🔄 Software updates: $UPDATES available${NC}"
        echo -e "${BLUE}   💡 Tip: Install updates during low-usage periods${NC}"
    else
        echo -e "${GREEN}🔄 Software updates: System up to date${NC}"
    fi
fi
echo

# 8. Actionable Recommendations
echo -e "${BOLD}${CYAN}💡 Quick Action Guide${NC}"
echo "Based on current system status:"

if [[ $LOAD_PCT -gt 100 ]]; then
    echo -e "${RED}🚨 URGENT: System overloaded${NC}"
    echo -e "   1. Close unnecessary applications immediately"
    echo -e "   2. Check Activity Monitor for resource hogs"
    echo -e "   3. Consider restart if issues persist"
elif [[ $SYSTEM_ISSUES -gt 1 ]]; then
    echo -e "${YELLOW}⚠️  System daemons elevated${NC}"
    echo -e "   1. Monitor system for 10-15 minutes"
    echo -e "   2. Check Console.app for error messages"
    echo -e "   3. Restart if problems continue"
elif [[ -n "$(pgrep mds)" ]] && [[ $(ps -Ao %cpu,comm | grep mds | awk '{sum += $1} END {print sum}' || echo "0") -gt 50 ]]; then
    echo -e "${BLUE}🔍 Spotlight indexing active${NC}"
    echo -e "   1. This is temporary (30-60 minutes typical)"
    echo -e "   2. System may run warm during indexing"
    echo -e "   3. Avoid intensive tasks during indexing"
    echo -e "   4. Do NOT force-quit Spotlight processes"
else
    echo -e "${GREEN}✅ System appears healthy${NC}"
    echo -e "   1. Continue normal usage"
    echo -e "   2. Monitor if any specific issues arise"
    echo -e "   3. Run this check again if performance degrades"
fi

echo
echo -e "${GREEN}✅ Health check complete.${NC}"
echo -e "${BLUE}💡 Pro tip: Run 'sudo dmesg | tail -20' to check recent system messages${NC}"
echo -e "${BLUE}💡 For detailed logs: Console.app or 'log show --last 1h --info'${NC}"
