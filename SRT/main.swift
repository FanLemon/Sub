//
//  main.swift
//  SRT
//
//  Created by Fan on 2019/12/03.
//  Copyright © 2019 Yoko. All rights reserved.
//

import Foundation



struct ConsoleLog {
    enum Color: String {
        case `reset` = "\u{001B}[0;0m"
        case black = "\u{001B}[0;30m"
        case red = "\u{001B}[0;31m"
        case green = "\u{001B}[0;32m"
        case yellow = "\u{001B}[0;33m"
        case blue = "\u{001B}[0;34m"
        case magenta = "\u{001B}[0;35m"
        case cyan = "\u{001B}[0;36m"
        case white = "\u{001B}[0;37m"
    }
    
    static func standard(message: String) {
        print(message)
    }
    
    static func error(message: String) {
        print(Color.red.rawValue + message + Color.`reset`.rawValue)
    }
    
    static func info(message: String) {
        print(Color.green.rawValue + message + Color.`reset`.rawValue)
    }
}




let usage = """

SRT Version 1.1

usage: SRT <infile> <outfile> <offset_ms | duration[03:24:19,456 --> 03:24:31,856]>
           <infile> <outfile> <offset_ms | duration[03:24:19,456 --> 03:24:31,856]> <outfile_separated>


"""

guard 4 == CommandLine.argc || 5 == CommandLine.argc else {
    ConsoleLog.info(message: usage)
    exit(EXIT_SUCCESS)
}


let inputFilePath = CommandLine.arguments[1]
let outputFilePath = CommandLine.arguments[2]
let offsetMilliseconds: Int
let offsetMsOrDuration = CommandLine.arguments[3]
var separatedFilePath: String?
if offsetMsOrDuration.contains("-->") {
    do {
        let duration = try SRTTimeDuration(srtLine: offsetMsOrDuration)
        offsetMilliseconds = duration.durationMilliseconds
    } catch SRTTimeParsingError.invalid(let reason) {
        ConsoleLog.error(message: "Input parameters Offset error: " + reason)
        exit(EXIT_SUCCESS)
    }
} else {
    guard let ms = Int(offsetMsOrDuration) else {
        ConsoleLog.error(message: "Input parameters Offset can not convert to Int, \(offsetMsOrDuration)")
        exit(EXIT_SUCCESS)
    }
    
    offsetMilliseconds = ms
}

ConsoleLog.info(message: "Offset \(offsetMilliseconds) Milliseconds")

if 5 == CommandLine.argc {
    separatedFilePath = CommandLine.arguments[4]
    ConsoleLog.info(message: "Separated File: [\(CommandLine.arguments[4])]")
}



let inputSRTBody: SRTBody
do {
    inputSRTBody = try SRTBody(filePath: inputFilePath)
} catch SRTTimeParsingError.invalid(let reason) {
    ConsoleLog.error(message: "Read input file error")
    ConsoleLog.error(message: reason)
    exit(EXIT_SUCCESS)
}


var shiftedSRTBody = inputSRTBody.offset(milliseconds: offsetMilliseconds)

if let sepedPath = separatedFilePath {
    let (left, right) = shiftedSRTBody.split()
    shiftedSRTBody = left
    
    do {
        try right.write(outputPath: sepedPath)
    } catch {
        ConsoleLog.error(message: "Output separeted srt file error")
        ConsoleLog.error(message: error.localizedDescription)
        exit(EXIT_SUCCESS)
    }
}

do {
    try shiftedSRTBody.write(outputPath: outputFilePath)
} catch {
    ConsoleLog.error(message: "Output srt file error")
    ConsoleLog.error(message: error.localizedDescription)
    exit(EXIT_SUCCESS)
}

ConsoleLog.info(message: "Completed. \(shiftedSRTBody.sentencesCount) Sentences.")







