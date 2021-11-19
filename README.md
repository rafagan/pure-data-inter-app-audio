# Pure Data Inter-App Audio
A sample project integrating Pure Data with iOS Inter-App Audio

To make the code works you need:

1. Enable `Inter-App Audio` Capability
2. Enable `Background Modes` Capability with `Audio, AirPlay, and Picture In Picture` checked
3. Install the following dependency using CocoaPods:

`pod 'libpd', :git => 'https://github.com/libpd/libpd', :submodules => true`

4. Configure the Info.plist properly with:

a) Core Foundation Bundle Display Name (somethimes Inter-App Audio doesn't works without that)

```
<key>CFBundleDisplayName</key>
<string>${PRODUCT_NAME}</string>
```

b) UIBackgroundModes audio (it's already there if you made step 2)

```
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

c) The audio component.
```
<key>AudioComponents</key>
<array>
  <dict>
    <key>manufacturer</key>
    <string>pdia</string> <!-- Put a 4 bytes unique name here, it's cannot be the same as any Inter-App Audio App installed. -->
    <key>name</key>
    <string>PureData</string> <!-- Plugin name -->
    <key>subtype</key>
    <string>iasp</string> <!-- Always iasp for Inter-App Audio -->
    <key>type</key>
    <string>aurg</string> <!-- Always aurg for Remote Generator Audio Unit (you also have Effects, Music Effects and Instruments) -->
    <key>version</key>
    <integer>1</integer> <!-- Always 1 -->
  </dict>
</array>
```

This should match exactly the code inside Inter-App Audio publish configuration

```
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
```
