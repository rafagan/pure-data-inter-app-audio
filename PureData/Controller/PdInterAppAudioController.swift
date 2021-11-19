import Foundation
import libpd

/// This will manager PD flows together with Inter-App Audio
class PdInterAppAudioController: PdAudioController {
    var this: PdInterAppAudioController!
    var connected = false
    var foreground = true
    
    /// Initialize Core Audio stuffs
    func configureInterAppAudioWith(sampleRate: Double, numChannels: Int) {
        this = self
        foreground = UIApplication.shared.applicationState != .background
        configureAudioSession(sampleRate: sampleRate, numChannels: numChannels)
        configureAudioUnit(sampleRate: sampleRate, numChannels: numChannels, inputEnabled: false)
        configureAppLifecycleListener()
    }
    
    /// iOS must provide AVAudioSession configurations
    func configureAudioSession(sampleRate: Double, numChannels: Int) {
        do {
            let s = AVAudioSession.sharedInstance()
            try s.setPreferredSampleRate(sampleRate)
            try s.setCategory(.playback, options: .mixWithOthers)
            try s.setPreferredOutputNumberOfChannels(numChannels)
            try s.setActive(true)
        } catch {
            Swift.print(error)
        }
    }
    
    /// Configure PD AudioUnit
    func configureAudioUnit(sampleRate: Double, numChannels: Int, inputEnabled: Bool) {
        let status = self.audioUnit.configure(
            withSampleRate: Float64(sampleRate),
            numberChannels: Int32(numChannels),
            inputEnabled: inputEnabled
        )
        
        if PdAudioStatus(rawValue: status) != PdAudioOK {
            Swift.print("Error while trying to configure PdAudioUnit: \(status)")
        } else {
            connectAndPublishOutputAudioUnit(outputUnit: self.audioUnit.audioUnit)
        }
    }
    
    /// Configure Inter-App Audio
    func connectAndPublishOutputAudioUnit(outputUnit: AudioUnit) {
        addAudioUnitPropertyListener(audioUnit: outputUnit)
        publishInterAppAudioUnit(audioUnit: outputUnit)
    }
    
    /// Responds to system events
    func configureAppLifecycleListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appHasGoneInBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterInForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
}

// MARK: PureData
extension PdInterAppAudioController {
    /// Init PD from file data
    func initPureData(name: String) {
        super.isActive = true
        if PdBase.openFile(name, path: Bundle.main.resourcePath) == nil {
            Swift.print("Failed to open PureData patch")
        }
    }
    
    /// Start or stop PD accordingly with Inter-App Audio connection and foreground  status
    func checkStartStopPureData() {
        if connected || foreground {
            super.isActive = true
        } else if !foreground {
            super.isActive = false
        }
    }
}

// MARK: Inter-App Audio
extension PdInterAppAudioController {
    /// Configure Inter-App property listeners, like the callback when connection status changes
    func addAudioUnitPropertyListener(audioUnit: AudioUnit) {
        CAV(AudioUnitAddPropertyListener(
            audioUnit,
            kAudioUnitProperty_IsInterAppConnected, { inUserData, inAudioUnit, inPropertyId, inScope, inBusNumber in
                inUserData
                    .assumingMemoryBound(to: PdInterAppAudioController.self)
                    .pointee
                    .audioUnitPropertyChangedListener(
                        inUserData: inUserData,
                        inAudioUnit: inAudioUnit,
                        inPropertyId: inPropertyId,
                        inScope: inScope,
                        inBusNumber: inBusNumber
                    )
            }, &this), details: "AudioUnitAddPropertyListener failed")
    }
    
    /// Update state accordingly with Inter-App Audio Unit property changes
    func audioUnitPropertyChangedListener(
        inUserData: UnsafeMutableRawPointer,
        inAudioUnit: AudioUnit,
        inPropertyId: AudioUnitPropertyID,
        inScope: AudioUnitScope,
        inBusNumber: AudioUnitElement
    ) {
        Swift.print("****** audio property changed notification received ******")
        if inPropertyId == kAudioUnitProperty_IsInterAppConnected {
            connected = isInterAppAudioHostConnected(audioUnit: inAudioUnit)
            onHostConnectionStatusChanged(audioUnit: inAudioUnit)
        }
    }
    
    /// Check if an Inter-App Audio host is connected
    func isInterAppAudioHostConnected(audioUnit: AudioUnit) -> Bool {
        var connectionStatus = UInt32()
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        CAV(AudioUnitGetProperty(
            audioUnit,
            kAudioUnitProperty_IsInterAppConnected,
            kAudioUnitScope_Global,
            0,
            &connectionStatus,
            &dataSize
        ), details: "AudioUnitGetProperty[IsInterAppConnected] failed")
        
        return connectionStatus != 0
    }
    
    /// Update state accordingly with Inter-App Audio Unit host connection status
    func onHostConnectionStatusChanged(audioUnit: AudioUnit) {
        checkStartStopPureData()
    }
    
    /// Make the app audio system be searcheable by another apps. This is the Inter-App audio foundation
    func publishInterAppAudioUnit(audioUnit: AudioUnit) {
        let pluginName = "PureData"
        let subType = "iasp"
        let manufacturer = "pdia"
        let version: UInt32 = 1
        
        for var description in [
            AudioComponentDescription(
                componentType: kAudioUnitType_RemoteGenerator,
                componentSubType: stringToFourCharCode(subType),
                componentManufacturer: stringToFourCharCode(manufacturer),
                componentFlags: 0,
                componentFlagsMask: 0
            )
        ] {
            CAV(AudioOutputUnitPublish(
                &description,
                pluginName as CFString,
                version,
                audioUnit
            ), details: "AudioOutputUnitPublish failed")
        }
    }
}

// MARK: App Lifecycle
extension PdInterAppAudioController {
    /// Background callback
    @objc func appHasGoneInBackground() {
        foreground = false
        checkStartStopPureData()
    }
    
    /// Foreground callback
    @objc func appWillEnterInForeground() {
        foreground = true
        checkStartStopPureData()
    }
}
