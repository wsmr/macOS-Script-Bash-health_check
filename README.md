# 🖥️ macOS Health Check

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-15.0+-blue.svg)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

A comprehensive, intelligent macOS system health monitoring script that provides actionable insights instead of just raw numbers.

## 🌟 Features

### 🧠 Intelligent Analysis
- **Context-aware diagnostics** - Understands what's normal vs concerning
- **Load average interpretation** with CPU core context
- **Spotlight indexing detection** with progress tracking
- **System process health monitoring** with escalating alerts
- **Memory pressure analysis** with actionable thresholds

### 💡 Actionable Recommendations
- **Immediate action steps** for critical issues
- **Timeline expectations** for temporary processes (like Spotlight rebuilding)
- **"Do NOT" warnings** to prevent harmful interventions
- **Severity-based color coding** with clear next steps

### 📊 Comprehensive Coverage
- System overview with load analysis
- Real-time CPU usage with multi-sample accuracy
- Spotlight/indexing status and progress
- System process health checks
- Memory usage analysis
- Issue detection and classification
- System activity context
- Quick action guide

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/macOS-Script-Bash-health_check.git
cd macos-health-check

# Make the script executable
chmod +x macos_health_check.sh

# Run the health check
./macos_health_check.sh
```

## 📋 Sample Output

```
🖥️  macOS Health Check Report
Generated: Sun Aug 24 16:05:35 +0530 2025
=========================================
📊 System Overview
macOS: 15.6.1
Load Averages: 12.28 (1m) 13.31 (5m) 11.34 (15m)
🚨 System Load: 153% (OVERLOADED - System struggling)
   💡 Action: Identify heavy processes, consider restart if persistent

🔍 Spotlight Indexing Status
💡 Spotlight is rebuilding index (high CPU is temporary)
   ⏰ Expected: 30-60 minutes for completion
   🌡️  System may be warm during this process
   ❌ Don't interrupt: Let indexing complete naturally

✅ All system processes healthy
```

## 🎯 Key Benefits

### 🔍 **Smart Problem Detection**
Unlike basic system monitors, this script:
- **Distinguishes temporary from persistent issues**
- **Explains WHY metrics are high** (e.g., Spotlight rebuilding)
- **Provides context for load averages** based on your CPU core count
- **Identifies system daemon health issues** that could indicate instability

### 📚 **Educational Value**
- **Teaches system administration concepts**
- **Explains what metrics mean** in practical terms
- **Builds understanding** of normal vs abnormal system behavior
- **Prevents unnecessary panic** about temporary high loads

### ⚡ **Actionable Intelligence**
- **Immediate steps** for critical situations
- **Monitoring guidance** for elevated metrics
- **Timeline expectations** for ongoing processes
- **Prevention tips** to avoid common issues

## 🛠️ Requirements

- **macOS 10.15+** (tested on macOS 15.6.1)
- **Bash shell** (default on macOS)
- **Basic command line tools** (`ps`, `df`, `uptime`, etc. - standard on macOS)
- **Admin privileges** for some advanced checks (script will prompt when needed)

## 📖 Understanding the Output

### Load Average Interpretation
```
Load Averages: 6.28 (1m) 6.61 (5m) 7.18 (15m)
CPU Cores: 8
📊 System Load: 78% (ELEVATED - Normal for active use)
```
- **Percentages are calculated** based on your CPU core count
- **<60% = Healthy**, **60-80% = Elevated**, **>80% = High**, **>100% = Overloaded**

### Spotlight Status
```
🔍 Spotlight Indexing Status
💡 Spotlight is rebuilding index (high CPU is temporary)
   ⏰ Expected: 30-60 minutes for completion
```
- **Intensive indexing is normal** after system changes
- **High CPU during rebuilding is expected**
- **Process will complete automatically**

### System Process Health
```
🔍 System Process Analysis
✅ launchd: 0.1% CPU (NORMAL)
❌ launchd: 26.2% CPU (HIGH)
```
- **System processes should typically use <5% CPU**
- **High system process CPU indicates potential issues**
- **Multiple elevated system processes suggest restart needed**

## 🚨 Common Scenarios

### 🔥 High CPU from Spotlight
**What you'll see:**
- High load averages (>100%)
- Multiple `mds`, `mds_stores`, `mdworker_shared` processes
- System appears to be struggling

**Script guidance:**
- ✅ Identifies this as temporary indexing
- ⏰ Provides completion timeline
- ❌ Warns against interrupting the process

### 💾 Memory Pressure
**What you'll see:**
- Low memory percentage free
- High memory usage from specific apps

**Script guidance:**
- 🎯 Identifies memory-heavy processes
- 💡 Provides cleanup recommendations
- ⚠️ Warns about critical memory levels

### ⚡ System Daemon Issues
**What you'll see:**
- High CPU from system processes (launchd, logd, etc.)
- System responsiveness issues

**Script guidance:**
- 🚨 Flags abnormal system process behavior
- 🔧 Recommends system restart when multiple daemons affected
- 📋 Suggests log checking commands

## 🔧 Advanced Usage

### Automated Monitoring
```bash
# Run every hour and log results
echo "0 * * * * /path/to/macos_health_check.sh >> /var/log/health_check.log 2>&1" | crontab -
```

### Performance Tracking
```bash
# Create timestamped reports
./macos_health_check.sh > "health_report_$(date +%Y%m%d_%H%M%S).txt"
```

### Integration with Monitoring Systems
The script's structured output can be parsed by monitoring systems or log aggregators.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Some areas where contributions would be especially valuable:

- 🎯 **Additional system checks** (disk health, network status, etc.)
- 🎨 **Output format options** (JSON, CSV, etc.)
- 🔧 **Integration helpers** for monitoring systems
- 📚 **Documentation improvements**
- 🌍 **Localization** for different languages

### Development Setup
```bash
git clone https://github.com/macOS-Script-Bash-health_check.git
cd macos-health-check

# Test your changes
./macos_health_check.sh

# Run with different scenarios to test logic
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the need for **intelligent system monitoring** beyond basic metrics
- Built for **macOS system administrators** who need actionable insights
- Designed to **educate users** about their system's behavior

## ⭐ Star History

If this script helped you understand and fix your macOS performance issues, please consider giving it a star! ⭐

## 📞 Support

- 🐛 **Bug reports**: [Open an issue](https://github.com/macOS-Script-Bash-health_check/issues)
- 💡 **Feature requests**: [Start a discussion](https://github.com/macOS-Script-Bash-health_check/discussions)
- 📖 **Questions**: Check existing issues or start a new discussion

---

**Made with ❤️ for macOS power users and system administrators**
