#pragma once
/**
 * SCR Simulation Logging — Lightweight logging for subsystems
 * ─────────────────────────────────────────────────────────────────────────────
 * Centralized logging with severity levels and file output.
 * Thread-safe for use from multiple subsystems.
 */

#include <string>
#include <fstream>
#include <iostream>
#include <mutex>
#include <chrono>
#include <ctime>
#include <iomanip>

namespace SCR::Log {

enum class Level { DEBUG, INFO, WARN, ERROR, FATAL };

inline const char* level_str(Level l) {
    switch (l) {
        case Level::DEBUG: return "DEBUG";
        case Level::INFO:  return "INFO ";
        case Level::WARN:  return "WARN ";
        case Level::ERROR: return "ERROR";
        case Level::FATAL: return "FATAL";
    }
    return "?????";
}

class Logger {
public:
    static Logger& instance() {
        static Logger inst;
        return inst;
    }

    void set_file(const std::string& path) {
        std::lock_guard<std::mutex> lock(mtx_);
        file_.open(path, std::ios::app);
    }

    void log(Level level, const std::string& subsystem, const std::string& msg) {
        auto now = std::chrono::system_clock::now();
        auto t = std::chrono::system_clock::to_time_t(now);
        auto tm = *std::localtime(&t);

        std::lock_guard<std::mutex> lock(mtx_);
        std::ostringstream oss;
        oss << std::put_time(&tm, "%H:%M:%S")
            << " [" << level_str(level) << "] "
            << subsystem << ": " << msg;

        std::string line = oss.str();
        std::cout << line << std::endl;
        if (file_.is_open()) {
            file_ << line << std::endl;
        }
    }

private:
    std::mutex mtx_;
    std::ofstream file_;
};

inline void info(const std::string& subsystem, const std::string& msg) {
    Logger::instance().log(Level::INFO, subsystem, msg);
}

inline void warn(const std::string& subsystem, const std::string& msg) {
    Logger::instance().log(Level::WARN, subsystem, msg);
}

inline void error(const std::string& subsystem, const std::string& msg) {
    Logger::instance().log(Level::ERROR, subsystem, msg);
}

inline void debug(const std::string& subsystem, const std::string& msg) {
    Logger::instance().log(Level::DEBUG, subsystem, msg);
}

} // namespace SCR::Log
