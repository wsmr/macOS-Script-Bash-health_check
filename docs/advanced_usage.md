# 🚀 Advanced Usage Guide

This guide covers advanced usage patterns, automation, and integration options for the macOS Health Check script.

## 📊 Automation and Monitoring

### Scheduled Health Checks

**Hourly monitoring with logging:**
```bash
# Add to crontab (crontab -e)
0 * * * * /path/to/macos_health_check.sh >> /var/log/health_check.log 2>&1
```

**Daily summary report:**
```bash
# Daily health report at 9 AM
0 9 * * * /path/to/macos_health_check.sh > ~/Desktop/daily_health_$(date +\%Y\%m\%d).txt
```

**Performance tracking over time:**
```bash
#!/bin/bash
# Save timestamped reports
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
/path/to/macos_health_check.sh > "/var/log/health_reports/health_$TIMESTAMP.txt"

# Keep only last 30 days
find /var/log/health_reports -name "health_*.txt" -mtime +30 -delete
```

### Alert Integration

**Email alerts for critical issues:**
```bash
#!/bin/bash
# health_alert.sh
REPORT=$(/path/to/macos_health_check.sh)

# Check for critical issues
if echo "$REPORT" | grep -q "🚨"; then
    echo "$REPORT" | mail -s "🚨 macOS Health Alert - $(hostname)" admin@company.com
fi
```

**Slack integration:**
```bash
#!/bin/bash
# slack_health.sh
REPORT=$(/path/to/macos_health_check.sh)
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# Send critical alerts to Slack
if echo "$REPORT" | grep -q "CRITICAL\|OVERLOADED"; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚨 Health Alert from $(hostname):\n\`\`\`$REPORT\`\`\`\"}" \
        "$WEBHOOK_URL"
fi
```

---

## 📈 Data Processing and Analysis

### Extracting Specific Metrics

**Get just the load average:**
```bash
./macos_health_check.sh | grep "Load Averages" | awk '{print $3, $4, $5}'
```

**Extract memory pressure percentage:**
```bash
./macos_health_check.sh | grep "Memory Pressure" | sed 's/.*: \([0-9]*\)%.*/\1/'
```

**List all high CPU processes:**
```bash
./macos_health_check.sh | grep -A 20 "🔥 CPU Usage" | tail -n +4 | head -n -1
```

### Creating Custom Reports

**CSV format for spreadsheet analysis:**
```bash
#!/bin/bash
# csv_health_report.sh

echo "Timestamp,LoadAvg1m,LoadAvg5m,LoadAvg15m,MemoryPressure,TopProcess,TopCPU"

REPORT=$(/path/to/macos_health_check.sh)
TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)
LOAD=$(echo "$REPORT" | grep "Load Averages" | awk '{print $3 "," $4 "," $5}')
MEMORY=$(echo "$REPORT" | grep "Memory Pressure" | sed 's/.*: \([0-9]*\)%.*/\1/')
TOP_PROCESS=$(echo "$REPORT" | grep -A 4 "🔥 CPU Usage" | tail -1 | awk '{print $6}')
TOP_CPU=$(echo "$REPORT" | grep -A 4 "🔥 CPU Usage" | tail -1 | awk '{print $3}')

echo "$TIMESTAMP,$LOAD,$MEMORY,$TOP_PROCESS,$TOP_CPU"
```

**JSON output for API integration:**
```bash
#!/bin/bash
# json_health_report.sh

generate_json_report() {
    local report=$1
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local hostname=$(hostname)
    
    # Extract key metrics (simplified version)
    local load_1m=$(echo "$report" | grep "Load Averages" | awk '{print $3}')
    local memory=$(echo "$report" | grep "Memory Pressure" | sed 's/.*: \([0-9]*\)%.*/\1/')
    
    cat <<EOF
{
    "timestamp": "$timestamp",
    "hostname": "$hostname",
    "load_average_1m": $load_1m,
    "memory_pressure_pct": $memory,
    "spotlight_active": $(echo "$report" | grep -q "Spotlight is rebuilding" && echo true || echo false)
}
EOF
}

REPORT=$(/path/to/macos_health_check.sh)
generate_json_report "$REPORT"
```

---

## 🔧 Customization Options

### Environment Variables

**Customize output format:**
```bash
#!/bin/bash
# Custom version of script with environment variables

# Disable colors for log files
export NO_COLORS=true

# Reduce verbosity
export QUIET_MODE=true

# Custom thresholds
export HIGH_LOAD_THRESHOLD=150
export CRITICAL_MEMORY_THRESHOLD=10

/path/to/macos_health_check.sh
```

### Script Modifications

**Add custom checks:**
```bash
# Add this section to your script

# Custom Application Monitoring
echo -e "${BOLD}${PURPLE}🎯 Custom Application Checks${NC}"

# Check specific applications
XCODE_CPU=$(ps -Ao %cpu,comm | grep -i xcode | head -1 | awk '{print $1}')
if [[ -n "$XCODE_CPU" && $(echo "$XCODE_CPU > 50" | bc -l) -eq 1 ]]; then
    echo -e "${YELLOW}⚠️  Xcode using ${XCODE_CPU}% CPU - Build in progress?${NC}"
fi

# Docker monitoring
if pgrep -q "Docker"; then
    DOCKER_CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | wc -l)
    echo -e "${BLUE}🐳 Docker: $((DOCKER_CONTAINERS-1)) containers running${NC}"
fi
```

**Custom thresholds:**
```bash
# Modify these variables in your script
HIGH_LOAD_PCT=80        # Default: 80%
CRITICAL_LOAD_PCT=100   # Default: 100% 
LOW_MEMORY_PCT=25       # Default: 25%
CRITICAL_MEMORY_PCT=15  # Default: 15%
HIGH_SYSTEM_CPU=10      # Default: 15% for system processes
```

---

## 🌐 Network and Remote Monitoring

### SSH-Based Fleet Monitoring

**Monitor multiple Macs remotely:**
```bash
#!/bin/bash
# fleet_health_check.sh

HOSTS=("mac1.local" "mac2.local" "mac3.local")

for host in "${HOSTS[@]}"; do
    echo "=== $host ==="
    ssh user@$host '/path/to/macos_health_check.sh' | grep -E "🚨|❌|⚠️"
    echo
done
```

**Parallel execution:**
```bash
#!/bin/bash
# parallel_fleet_check.sh

check_host() {
    local host=$1
    echo "=== $host ==="
    timeout 30 ssh user@$host '/path/to/macos_health_check.sh' 2>/dev/null | \
        grep -E "🚨|❌|⚠️|Load|Memory Pressure"
    echo
}

export -f check_host

# Check all hosts in parallel
echo "mac1.local mac2.local mac3.local" | tr ' ' '\n' | xargs -n 1 -P 3 -I {} bash -c 'check_host "$@"' _ {}
```

### REST API Integration

**POST health data to monitoring service:**
```bash
#!/bin/bash
# api_health_reporter.sh

API_ENDPOINT="https://your-monitoring-service.com/api/health"
API_KEY="your-api-key"

REPORT=$(/path/to/macos_health_check.sh)

# Extract key metrics
LOAD_1M=$(echo "$REPORT" | grep "Load Averages" | awk '{print $3}')
MEMORY_PCT=$(echo "$REPORT" | grep "Memory Pressure" | sed 's/.*: \([0-9]*\)%.*/\1/')
CRITICAL_ISSUES=$(echo "$REPORT" | grep -c "🚨")

# Send to API
curl -X POST \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"hostname\": \"$(hostname)\",
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"load_1m\": $LOAD_1M,
        \"memory_pressure\": $MEMORY_PCT,
        \"critical_issues\": $CRITICAL_ISSUES,
        \"full_report\": $(echo "$REPORT" | jq -R -s .)
    }" \
    "$API_ENDPOINT"
```

---

## 📱 Mobile and Dashboard Integration

### Simple Web Dashboard

**Basic HTML dashboard:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>macOS Fleet Health</title>
    <meta http-equiv="refresh" content="60">
</head>
<body>
    <h1>macOS Fleet Health Dashboard</h1>
    <div id="health-data">
        <!-- Updated by cron job writing to this file -->
    </div>
    <script>
        // Auto-refresh health data
        setInterval(() => {
            fetch('/health-data.json')
                .then(response => response.json())
                .then(data => updateDashboard(data));
        }, 30000);
    </script>
</body>
</html>
```

**Generate dashboard data:**
```bash
#!/bin/bash
# dashboard_generator.sh

generate_dashboard_data() {
    local hosts=("$@")
    echo "{"
    echo "  \"last_update\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"hosts\": ["
    
    for i in "${!hosts[@]}"; do
        local host="${hosts[$i]}"
        echo "    {"
        echo "      \"name\": \"$host\","
        
        # Get health data (you'd implement this)
        local health_data=$(ssh user@$host '/path/to/macos_health_check.sh' 2>/dev/null)
        
        if [[ -n "$health_data" ]]; then
            echo "      \"status\": \"online\","
            echo "      \"load\": $(echo "$health_data" | grep "Load Averages" | awk '{print $3}'),"
            echo "      \"memory\": $(echo "$health_data" | grep "Memory Pressure" | sed 's/.*: \([0-9]*\)%.*/\1/'),"
            echo "      \"issues\": $(echo "$health_data" | grep -c "🚨")"
        else
            echo "      \"status\": \"offline\","
            echo "      \"load\": null,"
            echo "      \"memory\": null,"
            echo "      \"issues\": null"
        fi
        
        if [[ $i -eq $((${#hosts[@]}-1)) ]]; then
            echo "    }"
        else
            echo "    },"
        fi
    done
    
    echo "  ]"
    echo "}"
}

HOSTS=("mac1.local" "mac2.local" "mac3.local")
generate_dashboard_data "${HOSTS[@]}" > /var/www/html/health-data.json
```

---

## 🔍 Performance Analysis

### Historical Trend Analysis

**Track performance over time:**
```bash
#!/bin/bash
# trend_analysis.sh

LOGS_DIR="/var/log/health_reports"
DAYS_BACK=7

echo "Performance Trends (Last $DAYS_BACK days)"
echo "========================================"

# Average load over time
echo "Average Load by Day:"
for i in $(seq $DAYS_BACK -1 1); do
    DATE=$(date -j -v-${i}d +%Y%m%d)
    AVG_LOAD=$(find "$LOGS_DIR" -name "health_${DATE}*.txt" -exec grep "Load Averages" {} \; | \
               awk '{sum+=$3; count++} END {if(count>0) printf "%.2f", sum/count; else print "N/A"}')
    echo "  $(date -j -v-${i}d +%Y-%m-%d): $AVG_LOAD"
done

# Memory pressure trends
echo -e "\nMemory Pressure Trends:"
for i in $(seq $DAYS_BACK -1 1); do
    DATE=$(date -j -v-${i}d +%Y%m%d)
    AVG_MEM=$(find "$LOGS_DIR" -name "health_${DATE}*.txt" -exec grep "Memory Pressure" {} \; | \
              sed 's/.*: \([0-9]*\)%.*/\1/' | awk '{sum+=$1; count++} END {if(count>0) printf "%.1f%%", sum/count; else print "N/A"}')
    echo "  $(date -j -v-${i}d +%Y-%m-%d): $AVG_MEM"
done
```

### Resource Usage Patterns

**Identify peak usage times:**
```bash
#!/bin/bash
# usage_patterns.sh

analyze_usage_patterns() {
    local logs_dir="$1"
    
    echo "Peak Usage Analysis"
    echo "=================="
    
    # Find highest load times
    echo "Highest Load Times:"
    find "$logs_dir" -name "health_*.txt" -exec grep -H "Load Averages" {} \; | \
        sed 's/.*health_\([0-9_]*\)\.txt.*Load Averages: \([0-9.]*\).*/\1 \2/' | \
        sort -k2 -nr | head -5 | while read timestamp load; do
            formatted_time=$(echo "$timestamp" | sed 's/\([0-9]\{8\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1 \2:\3:\4/')
            echo "  $formatted_time - Load: $load"
        done
    
    echo -e "\nHourly Load Distribution:"
    find "$logs_dir" -name "health_*.txt" -exec grep -H "Load Averages" {} \; | \
        sed 's/.*health_[0-9]*_\([0-9]\{2\}\)[0-9]*\.txt.*Load Averages: \([0-9.]*\).*/\1 \2/' | \
        awk '{load[$1] += $2; count[$1]++} END {
            for(hour in load) printf "  %02d:00 - Avg Load: %.2f\n", hour, load[hour]/count[hour]
        }' | sort
}

analyze_usage_patterns "/var/log/health_reports"
```

---

## ⚙️ Integration Examples

### Nagios/Icinga Integration

**Nagios check script:**
```bash
#!/bin/bash
# check_macos_health.sh (Nagios plugin format)

CRITICAL_LOAD=200
WARNING_LOAD=150
CRITICAL_MEMORY=15
WARNING_MEMORY=25

REPORT=$(/path/to/macos_health_check.sh)

# Extract metrics
LOAD_PCT=$(echo "$REPORT" | grep "System Load" | sed 's/.*: \([0-9]*\)%.*/\1/')
MEMORY_PCT=$(echo "$REPORT" | grep "Memory Pressure" | sed 's/.*: \([0-9]*\)%.*/\1/')
CRITICAL_COUNT=$(echo "$REPORT" | grep -c "🚨")

# Nagios exit codes: 0=OK, 1=WARNING, 2=CRITICAL, 3=UNKNOWN
if [[ $CRITICAL_COUNT -gt 0 ]] || [[ $LOAD_PCT -gt $CRITICAL_LOAD ]] || [[ $MEMORY_PCT -lt $CRITICAL_MEMORY ]]; then
    echo "CRITICAL - Load: ${LOAD_PCT}%, Memory: ${MEMORY_PCT}% free, Issues: $CRITICAL_COUNT"
    exit 2
elif [[ $LOAD_PCT -gt $WARNING_LOAD ]] || [[ $MEMORY_PCT -lt $WARNING_MEMORY ]]; then
    echo "WARNING - Load: ${LOAD_PCT}%, Memory: ${MEMORY_PCT}% free"
    exit 1
else
    echo "OK - Load: ${LOAD_PCT}%, Memory: ${MEMORY_PCT}% free"
    exit 0
fi
```

### Prometheus Integration

**Metrics exporter:**
```bash
#!/bin/bash
# prometheus_exporter.sh

METRICS_FILE="/tmp/macos_health_metrics.prom"
REPORT=$(/path/to/macos_health_check.sh)

{
    echo "# HELP macos_load_average_1m Current 1-minute load average"
    echo "# TYPE macos_load_average_1m gauge"
    echo "macos_load_average_1m $(echo "$REPORT" | grep "Load Averages" | awk '{print $3}')"
    
    echo "# HELP macos_memory_pressure_percent Memory pressure percentage"
    echo "# TYPE macos_memory_pressure_percent gauge"
    echo "macos_memory_pressure_percent $(echo "$REPORT" | grep "Memory Pressure" | sed 's/.*: \([0-9]*\)%.*/\1/')"
    
    echo "# HELP macos_critical_issues_count Number of critical issues detected"
    echo "# TYPE macos_critical_issues_count gauge"
    echo "macos_critical_issues_count $(echo "$REPORT" | grep -c "🚨")"
    
    echo "# HELP macos_spotlight_indexing Whether Spotlight is currently indexing"
    echo "# TYPE macos_spotlight_indexing gauge"
    echo "macos_spotlight_indexing $(echo "$REPORT" | grep -q "Spotlight is rebuilding" && echo 1 || echo 0)"
    
} > "$METRICS_FILE"

echo "Metrics exported to $METRICS_FILE"
```

This comprehensive advanced usage guide should help users integrate the health check script into their monitoring infrastructure and customize it for their specific needs! 🚀
