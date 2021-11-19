import Foundation

/// Core Audio Validate
/// Print errors in a better way (check https://www.osstatus.com/ to understand status codes)
func CAV(_ error: OSStatus, details: String? = nil) {
    guard error != noErr else { return }
    
    var result: String = ""
    var char = Int(error.bigEndian)
    
    for _ in 0..<4 {
        guard isprint(Int32(char & 255)) == 1 else {
            result = "\(error)"
            break
        }
        result += UnicodeScalar(char & 255)!.description
        char = char / 256
    }
    
    print("Error: \(details ?? "") (\(result))")
}

/// We need to represent Core Audio manufacturers, types and subtypes four character strings as UInt32 number
func stringToFourCharCode(_ value: String) -> FourCharCode {
    let arrayUInt8 = value.utf8.map { (val) -> UInt8 in
        return val
    }
    
    var code: FourCharCode = UInt32(arrayUInt8[0])
    for i in 1..<4 {
        code <<= 8
        code |= UInt32(arrayUInt8[i])
    }
    
    return code
}
