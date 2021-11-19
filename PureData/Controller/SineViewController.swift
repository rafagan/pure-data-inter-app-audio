import UIKit
import libpd

/// Sine tone example
class SineViewController: UIViewController {
    /// PdAudioController
    var audioController = PdInterAppAudioController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Inter-App Audio Initialization
        audioController?.configureInterAppAudioWith(sampleRate: 44100, numChannels: 2)
        
        /// Pure Data Initialization
        audioController?.initPureData(name: "sinepiano.pd")
    }
    
    /// Send tone to PD
    func playPiano(note: Double) {
        PdBase.send(Float(note) + 72, toReceiver: "midinote")
        PdBase.sendBang(toReceiver: "trigger")
    }
    
    /// Let's send F note frequency to PD when the button is pressed
    @IBAction func onTouchPlay(_ sender: Any) {
        playPiano(note: 5)
    }
}
