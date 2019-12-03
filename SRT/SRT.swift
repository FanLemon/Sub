//
//  SRT.swift
//  SRT
//
//  Created by Fan on 2019/12/03.
//  Copyright © 2019 Yoko. All rights reserved.
//

import Foundation


let MILLISECONDS_PER_SECOND = 1000
let MILLISECONDS_PER_MINUTE = 60 * MILLISECONDS_PER_SECOND
let MILLISECONDS_PER_HOUR = 60 * MILLISECONDS_PER_MINUTE


// SRT Time Duration
// 03:24:19,456 --> 05:26:19,149

enum SRTTimeParsingError: Error {
    case invalid(reason: String)
}

func parsingSexagenary(label: String) throws -> Int {
    guard label.count == 2 else {
        throw SRTTimeParsingError.invalid(reason: "Sexagenary not 2 chars.")
    }
    
    guard let value = Int(label) else {
        throw SRTTimeParsingError.invalid(reason: "Sexagenary convert to Int failed.")
    }
    
    guard value < 60, value >= 0 else {
        throw SRTTimeParsingError.invalid(reason: "Sexagenary over 60 or less than 0.")
    }
    
    return value
}

struct SRTTime {
    var hour: Int
    var minute: Int
    var second: Int
    var millisecond: Int
    
    init() {
        hour = 0
        minute = 0
        second = 0
        millisecond = 0
    }
    
    init(srtTimeLabel: String) throws {
        let sample = "05:26:19,149"
        
        guard srtTimeLabel.count == sample.count else {
            throw SRTTimeParsingError.invalid(reason: "Time chars count error. [\(srtTimeLabel)]")
        }
        
        let hmsComponents = srtTimeLabel.components(separatedBy: ":")
        guard hmsComponents.count == 3 else {
            throw SRTTimeParsingError.invalid(reason: "Time hms components error. [\(hmsComponents)]")
        }
        
        do {
            hour = try parsingSexagenary(label: hmsComponents[0])
        } catch SRTTimeParsingError.invalid(let reason) {
            throw SRTTimeParsingError.invalid(reason: "Time parsing hour error - " + reason)
        }
        
        do {
            minute = try parsingSexagenary(label: hmsComponents[1])
        } catch SRTTimeParsingError.invalid(let reason) {
            throw SRTTimeParsingError.invalid(reason: "Time parsing minute error - " + reason)
        }
        
        let ssComponents = hmsComponents[2].components(separatedBy: ",")
        guard ssComponents.count == 2 else {
            throw SRTTimeParsingError.invalid(reason: "Time parsing seconds components error")
        }
        
        do {
            second = try parsingSexagenary(label: ssComponents[0])
        } catch SRTTimeParsingError.invalid(let reason) {
            throw SRTTimeParsingError.invalid(reason: "Time parsing second error - " + reason)
        }
        
        guard ssComponents[1].count == 3, let ms = Int(ssComponents[1]), ms >= 0 else {
            throw SRTTimeParsingError.invalid(reason: "Time parsing millisecond error.")
        }
        
        millisecond = ms
    }
    
    init(milliseconds: Int) {
        guard milliseconds > 0 else {
            hour = 0
            minute = 0
            second = 0
            millisecond = 0
            return
        }
        
        var ms = milliseconds
        
        hour = ms / MILLISECONDS_PER_HOUR
        ms -= (hour * MILLISECONDS_PER_HOUR)
        
        minute = ms / MILLISECONDS_PER_MINUTE
        ms -= minute * MILLISECONDS_PER_MINUTE
        
        second = ms / MILLISECONDS_PER_SECOND
        ms -=  second * MILLISECONDS_PER_SECOND
        
        millisecond = ms
    }
    
    var timeMilliseconds: Int {
        let mmm = millisecond
        let sss = second * MILLISECONDS_PER_SECOND
        let min = minute * MILLISECONDS_PER_MINUTE
        let hhh = hour * MILLISECONDS_PER_HOUR
        
        return hhh + min + sss + mmm
    }
    
    var srtLabel: String {
        return String(format: "%02d:%02d:%02d,%03d", hour, minute, second, millisecond)
    }
    
    func offset(milliseconds: Int) -> SRTTime {
        return SRTTime(milliseconds: self.timeMilliseconds + milliseconds)
    }
}


let SRTTimeDurationDelimiter = " --> "

struct SRTTimeDuration {
    var start: SRTTime
    var end: SRTTime
    
    init() {
        start = SRTTime()
        end = SRTTime()
    }
    
    init(startTime: SRTTime, endTime: SRTTime) {
        start = startTime
        end = endTime
    }
    
    init(srtLine: String) throws {
        let sample = "03:24:19,456 --> 05:26:19,149"
        
        guard sample.count == srtLine.count else {
            throw SRTTimeParsingError.invalid(reason: "Duration chars count error.")
        }
        
        let components = srtLine.components(separatedBy: SRTTimeDurationDelimiter)
        guard components.count == 2 else {
            throw SRTTimeParsingError.invalid(reason: "Duration components error.")
        }
        
        do {
            start = try SRTTime(srtTimeLabel: components[0])
        } catch SRTTimeParsingError.invalid(let reason) {
            throw SRTTimeParsingError.invalid(reason: "Duration start error - " + reason)
        }
        
        do {
            end = try SRTTime(srtTimeLabel: components[1])
        } catch SRTTimeParsingError.invalid(let reason) {
            throw SRTTimeParsingError.invalid(reason: "Duration end error - " + reason)
        }
    }
    
    var srtLine: String {
        return start.srtLabel + SRTTimeDurationDelimiter + end.srtLabel
    }
    
    var durationMilliseconds: Int {
        return end.timeMilliseconds - start.timeMilliseconds
    }
    
    func offset(milliseconds: Int) -> SRTTimeDuration {
        return SRTTimeDuration(startTime: start.offset(milliseconds: milliseconds), endTime: end.offset(milliseconds: milliseconds))
    }
}


struct SRTSentence {
    var number: Int = 0
    var duration: SRTTimeDuration = SRTTimeDuration()
    var text: String = ""
    var blank: String = "\n"
    
    init(aNumber: Int, durationLabel: String, content: String) throws {
        do {
            duration = try SRTTimeDuration(srtLine: durationLabel)
            number = aNumber
            text = content
        } catch SRTTimeParsingError.invalid(let reason) {
            throw SRTTimeParsingError.invalid(reason: "SRTSentence [\(aNumber)] -\(content)- create error - " + reason)
        }
    }
    
    var bytes: Data {
        if let data = srtString.data(using: String.Encoding.utf8) {
            return data
        }
        
        return Data()
    }
    
    var srtString: String {
        return String(number) + "\n" + duration.srtLine + "\n" + text + blank
    }
}




struct SRTBody {
    var sentences: [SRTSentence]
    
    var sentencesCount: Int {
        return sentences.count
    }
    
    init(sens: [SRTSentence]) {
        sentences = sens
    }
    
    init(filePath: String) throws {
        sentences = []
        
        let sourceFileContent: String
        do {
            sourceFileContent = try String(contentsOfFile: filePath)
        } catch {
            throw error
        }
        
        // 1. detect time
        // 2. check can build a entry, if yes, show it.
        // 3. clear cachedLines
        let sourceLines = sourceFileContent.components(separatedBy: CharacterSet.newlines)
        var linesNumber: Int = 0
        var cachedLines: [String] = []
        var srtSentenceNumber: Int = 0
        for line in sourceLines {
            cachedLines.append(line)
            
            if let _ = try? SRTTimeDuration(srtLine: line) {
                // number
                // time
                // xxx
                // number
                // time
                let stripedLines = cachedLines.filter({ (s: String) -> Bool in
                    if s.count <= 0 || s == "" {
                        return false
                    }
                    
                    return true
                })
                
                if stripedLines.count >= 5 {
                    srtSentenceNumber += 1
                    
                    var cnt: String = ""
                    for i in 2 ..< (stripedLines.count-2) {
                        cnt += stripedLines[i]
                        cnt += "\n"
                    }
                    
                    do {
                        let sentence = try SRTSentence(aNumber: srtSentenceNumber, durationLabel: stripedLines[1], content: cnt)
                        sentences.append(sentence)
                    } catch SRTTimeParsingError.invalid(let reason) {
                        throw SRTTimeParsingError.invalid(reason: "line: \(linesNumber) - " + reason)
                    } catch {
                        throw SRTTimeParsingError.invalid(reason: "line: \(linesNumber) Other error")
                    }
                    
                    cachedLines.removeAll()
                    cachedLines.append(stripedLines[stripedLines.count-2])
                    cachedLines.append(stripedLines[stripedLines.count-1])
                }
            }
            
            linesNumber += 1
        }
        
        let stripedLines = cachedLines.filter({ (s: String) -> Bool in
            if s.count <= 0 || s == "" {
                return false
            }
            
            return true
        })
        
        // number
        // time
        // xxx
        if stripedLines.count >= 3 {
            srtSentenceNumber += 1
            
            var cnt: String = ""
            for i in 2 ..< stripedLines.count {
                cnt += stripedLines[i]
                cnt += "\n"
            }
            
            do {
                let sentence = try SRTSentence(aNumber: srtSentenceNumber, durationLabel: stripedLines[1], content: cnt)
                sentences.append(sentence)
            } catch SRTTimeParsingError.invalid(let reason) {
                throw SRTTimeParsingError.invalid(reason: "line: \(linesNumber) - " + reason)
            } catch {
                throw SRTTimeParsingError.invalid(reason: "line: \(linesNumber) Other error")
            }
        }
    }
    
    func offset(milliseconds: Int) -> SRTBody {
        let destSentences = sentences.map { (src: SRTSentence) -> SRTSentence in
            var dest = src
            dest.duration = src.duration.offset(milliseconds: milliseconds)
            return dest
        }
        
        return SRTBody(sens: destSentences)
    }
    
    func split() -> (SRTBody, SRTBody) {
        var leftSentences: [SRTSentence] = []
        var rightSentences: [SRTSentence] = []
        
        for src in sentences {
            var left = src
            var right = src
            let (leftText, rightText) = src.text.separated()
            left.text = leftText
            right.text = rightText
            
            leftSentences.append(left)
            rightSentences.append(right)
        }
        
        return (SRTBody(sens: leftSentences), SRTBody(sens: rightSentences))
    }
    
    var bodyString: String {
        return sentences.reduce("", { (str: String, src: SRTSentence) -> String in
            return str + src.srtString
        })
    }
    
    func write(outputPath: String) throws {
        try bodyString.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: String.Encoding.utf8)
    }
}

extension String {
    func separated() -> (String, String) {
        var left = ""
        var right = ""
        
        let lines = self.components(separatedBy: CharacterSet.newlines)
        
        switch lines.count {
            
        case 2:
            left = lines[0] + "\n"
            right = lines[0] + "\n"
        case 3:
            left = lines[0] + "\n"
            right = lines[1] + "\n"
        case 4:
            left = lines[0] + "\n"
            right = lines[1] + lines[2] + "\n"
        case 5:
            left = lines[0] + lines[1] + "\n"
            right = lines[2] + lines[3] + "\n"
        case 6:
            left = lines[0] + lines[1] + lines[2] + "\n"
            right = lines[3] + lines[4] + lines[5] + "\n"
            
        default:
            left = lines[0] + "\n"
            for i in 1 ..< lines.count {
                right += lines[i] + "\n"
            }
        }
        
        return (left, right)
    }
}





