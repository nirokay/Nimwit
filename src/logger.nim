import os, times, tables, strformat, strutils
import typedefs, configfile

type LogFile* = enum
    logDimscord = "dimscord.log",
    logError    = "error.log",
    logDebug    = "debug.log"


proc logger*[T](logFile: LogFile, data: T) =
    let
        logDir: string = config.fileLocations[dirLogs]
        file: string = logDir & $logFile
        timestamp: string = getTime().format("YYYY-MM-dd  HH:mm:ss")
        text: string = timestamp & "\n\t" & $data
    
    if not logDir.dirExists():
        logDir.createDir()

    echo &"Debug Entry:\n\tFile: {file}\n\tTimestamp: {timestamp}"
    let f = file.open(fmAppend)
    f.write(text & "\n\n")
    f.close()

proc logger*(data: Exception) =
    logger(logError, data.msg)

proc debuglogger*[T](data: T) =
    logger(logDebug, data)
