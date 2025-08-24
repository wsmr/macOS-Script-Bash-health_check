# 🔧 Troubleshooting Guide

This guide helps you understand and resolve common issues detected by the macOS Health Check script.

## 🚨 Critical System Issues

### High launchd CPU (>20%)

**What it means:**
- `launchd` is the root process manager on macOS
- High CPU usage indicates system daemons are struggling
- Usually suggests system instability or daemon crashes

**Symptoms:**
```
❌ launchd: 26.2% CPU (HIGH)
   💡 Action: System restart recommended
```

**Solutions:**
1. **Immediate**: Check what's causing daemon restarts
   ```bash
   sudo dmesg | tail -20
   log show --last 1h --predicate 'category == "daemon"' --info
   ```

2. **If persistent**: Restart to reset all system daemons
   ```bash
   sudo shutdown -r now
   ```

3. **Prevention**: Avoid force-quitting system processes

---

### Memory Pressure Critical (<15% free)

**What it means:**
- System is running out of available RAM
- macOS is aggressively swapping to disk
- Performance will degrade significantly

**Symptoms:**
```
🚨 Memory Pressure: 12% free (CRITICAL)
   💡 Action: Close apps, restart if needed, check for memory leaks
```

**Solutions:**
1. **Immediate**: Close unnecessary applications
   ```bash
   # Check biggest memory users
   ps -Ao pid,user,%mem,rss,comm -m | head -10
   ```

2. **Identify memory hogs**: Look for apps using >1GB RAM abnormally

3. **Clear caches** (requires restart):
   ```bash
   sudo rm -rf /Library/Caches/*
   rm -rf ~/Library/Caches/*
   ```

4. **Restart** if memory doesn't free up

---

### System Load >200%

**What it means:**
- System is severely overloaded
- More work queued than CPU can handle
- Usually indicates runaway processes

**Symptoms:**
```
🚨 System Load: 218% (OVERLOADED - System struggling)
   💡 Action: Identify heavy processes, consider restart if persistent
```

**Solutions:**
1. **Identify culprits**:
   ```bash
   ps -Ao pid,user,%cpu,comm -r | head -10
   ```

2. **Check for Spotlight indexing** (this is normal and temporary)

3. **Force-quit problematic apps** if not system processes

4. **Restart** if multiple system processes are high

---

## ⚡ Spotlight Indexing Issues

### Understanding Spotlight Behavior

**Normal Spotlight Rebuilding:**
```
🔍 Spotlight Indexing Status
💡 Spotlight is rebuilding index (high CPU is temporary)
   ⏰ Expected: 30-60 minutes for completion
   🌡️  System may be warm during this process
```

**When Spotlight indexing is happening:**
- **mds_stores**: 50-300% CPU (uses multiple cores)
- **mds**: 20-60% CPU (coordinator process)
- **mdworker_shared**: Multiple processes at 10-50% each

**This is NORMAL and should NOT be interrupted.**

### Spotlight Stuck or Corrupted

**Symptoms:**
- Spotlight processes consuming high CPU for >2 hours
- System extremely slow for extended periods
- Spotlight search not working

**Solutions:**
1. **Check indexing status**:
   ```bash
   sudo mdutil -a -s
   ```

2. **If corrupted, rebuild clean**:
   ```bash
   # Disable indexing
   sudo mdutil -a -i off
   
   # Kill current processes
   sudo killall mds_stores
   sudo killall mds
   
   # Remove corrupted index
   sudo rm -rf /.Spotlight-V100
   
   # Re-enable (will rebuild)
   sudo mdutil -a -i on
   sudo mdutil -E /
   ```

3. **Add problematic folders to Privacy** (System Preferences > Spotlight > Privacy):
   - Large development directories
   - Virtual machine files
   - node_modules folders

---

## 💾 Memory and Performance Issues

### Apps Using Excessive Memory

**Identifying memory hogs:**
```
🐘 Processes using >1GB RAM:
  PID 1234: 2048MB - Google Chrome Helper (Renderer)
  PID 5678: 1536MB - IntelliJ IDEA Ultimate
```

**Solutions:**
1. **For browsers**: Close unused tabs, check for problematic extensions
2. **For IDEs**: Reduce memory allocation settings
3. **For unknown processes**: Research what they are before killing

### Swap Usage High

**Check swap usage:**
```bash
sysctl vm.swapusage
```

**If swap is high (>2GB):**
1. Close memory-intensive apps
2. Restart applications that have been running long
3. Consider adding more RAM if consistently high

---

## 🔄 Process Management Issues

### Zombie Processes

**What they are:**
- Processes that have finished but haven't been cleaned up
- Usually harmless but can indicate issues

**Symptoms:**
```
💀 Zombie processes found:
  PID 1234: defunct_process
```

**Solutions:**
1. **Usually resolve automatically** - wait 5-10 minutes
2. **If persistent**: Restart the parent process
3. **If many zombies**: System restart recommended

### Too Many Processes from One App

**Symptoms:**
```
📊 Apps with many processes (>15):
  Google Chrome: 23 processes
  Firefox: 18 processes
```

**Solutions:**
1. **For browsers**: This is often normal (one process per tab)
2. **Check for runaway spawning**: Look for rapidly increasing process counts
3. **Restart the application** if process count seems excessive

---

## 🌡️ System Temperature Issues

### High Temperature During Normal Use

**Common causes identified by script:**
- Spotlight indexing (temporary)
- Browser with heavy JavaScript
- Multiple high-CPU processes

**Solutions:**
1. **If Spotlight is indexing**: Wait for completion (30-60 minutes)
2. **Close resource-intensive browser tabs**
3. **Check for dust buildup** (especially older Macs)
4. **Reset SMC** (System Management Controller):
   ```bash
   # For newer Macs: Shut down, press power for 10 seconds
   # For older Macs: Check Apple's SMC reset instructions
   ```

---

## 🛠️ Script-Specific Issues

### Script Hangs or Fails

**If the script stops responding:**
1. **Kill with Ctrl+C**
2. **Check for sudo password prompts**
3. **Run individual commands to isolate issue**

### Permissions Errors

**For "Operation not permitted" errors:**
1. **Grant Terminal Full Disk Access**:
   - System Preferences > Security & Privacy > Privacy
   - Full Disk Access > Add Terminal

2. **Some operations require admin privileges** (script will prompt)

### Inaccurate Results

**If CPU percentages seem wrong:**
- **Run script multiple times** - CPU usage is dynamic
- **High sampling variance is normal** during system activity
- **5-second average helps** but may still show spikes

---

## 📞 Getting More Help

### Additional Diagnostic Commands

**Check system logs:**
```bash
# Recent system messages
sudo dmesg | tail -20

# Application crashes
log show --last 24h --predicate 'eventType == "logEvent" and subsystem == "com.apple.crashreporter"'

# Disk errors
log show --last 24h --predicate 'category == "disk"'
```

**Hardware diagnostics:**
```bash
# Hardware test (requires restart)
# Hold D during boot for Apple Hardware Test

# Temperature monitoring (if available)
sudo powermetrics -n 1 | grep -i temp
```

### When to Seek Further Help

**Contact Apple Support if:**
- Multiple system processes consistently high after restarts
- Frequent kernel panics or system crashes
- Hardware temperature consistently above normal
- Disk errors appearing in logs

**Consider professional help if:**
- System performance doesn't improve after following all recommendations
- Recurring issues that script identifies but solutions don't resolve
- Suspected hardware failure (overheating, random shutdowns)

---

## 🎯 Prevention Tips

### Regular Maintenance

1. **Restart weekly** to reset system daemons
2. **Keep software updated** to avoid known issues
3. **Monitor disk space** - keep >20% free
4. **Clean caches monthly** (automated tools available)
5. **Backup regularly** to avoid data loss during troubleshooting

### Usage Best Practices

1. **Don't force-quit system processes** (launchd, WindowServer, etc.)
2. **Let Spotlight finish indexing** after major changes
3. **Close unused browser tabs** to free memory
4. **Quit apps you're not using** rather than just minimizing
5. **Use Activity Monitor** to identify resource-heavy processes
