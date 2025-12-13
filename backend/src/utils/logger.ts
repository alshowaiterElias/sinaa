type LogLevel = 'info' | 'warn' | 'error' | 'debug';

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  data?: unknown;
}

const formatLog = (level: LogLevel, message: string, data?: unknown): LogEntry => {
  return {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...(data !== undefined ? { data } : {}),
  };
};

const colorize = (level: LogLevel, text: string): string => {
  const colors = {
    info: '\x1b[36m',    // Cyan
    warn: '\x1b[33m',    // Yellow
    error: '\x1b[31m',   // Red
    debug: '\x1b[35m',   // Magenta
  };
  const reset = '\x1b[0m';
  return `${colors[level]}${text}${reset}`;
};

const formatOutput = (entry: LogEntry): string => {
  const levelStr = colorize(entry.level, entry.level.toUpperCase().padEnd(5));
  const base = `[${entry.timestamp}] ${levelStr} ${entry.message}`;
  if (entry.data) {
    return `${base}\n${JSON.stringify(entry.data, null, 2)}`;
  }
  return base;
};

export const logger = {
  info: (message: string, data?: unknown): void => {
    const entry = formatLog('info', message, data);
    console.log(formatOutput(entry));
  },

  warn: (message: string, data?: unknown): void => {
    const entry = formatLog('warn', message, data);
    console.warn(formatOutput(entry));
  },

  error: (message: string, data?: unknown): void => {
    const entry = formatLog('error', message, data);
    console.error(formatOutput(entry));
  },

  debug: (message: string, data?: unknown): void => {
    if (process.env.NODE_ENV === 'development') {
      const entry = formatLog('debug', message, data);
      console.debug(formatOutput(entry));
    }
  },

  request: (method: string, path: string, statusCode: number, duration: number): void => {
    const color = statusCode >= 400 ? '\x1b[31m' : statusCode >= 300 ? '\x1b[33m' : '\x1b[32m';
    const reset = '\x1b[0m';
    console.log(
      `[${new Date().toISOString()}] ${method.padEnd(7)} ${path} ${color}${statusCode}${reset} ${duration}ms`
    );
  },
};

export default logger;
