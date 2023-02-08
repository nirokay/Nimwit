import os, times, tables, strformat, strutils
import typedefs

type LogFile* = enum
    logDimscord = "dimscord.log",
    logError    = "error.log",
    logDebug    = "debug.log"


proc logger*[T](logFile: LogFile, data: T) =
    let
        logDir: string = getLocation(dirLogs)
        file: string = logDir & $logFile
        timestamp: string = getTime().format("YYYY-MM-dd  HH:mm:ss")
        text: string = timestamp & "\n\t" & $data
    
    if not logDir.dirExists():
        logDir.createDir()

    echo &"Debug Entry:\n\tFile: {file}\n\tTimestamp: {timestamp}\n\tContent: {$data}"
    let f = file.open(fmAppend)
    f.write(text & "\n\n")
    f.close()

proc logger*(data: Exception | ref Exception) =
    let text: string = &"**{data.name}**: {data.msg}"
    logger(logError, text)

proc debuglogger*[T](data: T) =
    logger(logDebug, data)
