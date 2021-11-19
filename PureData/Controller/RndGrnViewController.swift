import UIKit
import libpd

/// Noise generation example
class RndGrnViewController: UIViewController {
    /// PdAudioController
    var audioController = PdInterAppAudioController()
    
    /// Noise parameters to PD file
    var osc: Float = 32
    var pha: Float = 64
    var rnd: Float = 127
    var onOff: Float = 0
    var vol: Float = 0.15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Inter-App Audio Initialization
        audioController?.configureInterAppAudioWith(sampleRate: 44100, numChannels: 2)
        
        /// Pure Data Initialization
        audioController?.initPureData(name: "rnd_grn.pd")
    }
    
    @IBAction func makeNoise(_ sender: Any) {
        /// When the button is pressed, the parameters are send to pd file to start making some noise
        PdBase.send(osc, toReceiver: "osc")
        PdBase.send(pha, toReceiver: "pha")
        PdBase.send(rnd, toReceiver: "rnd")
        PdBase.send(onOff, toReceiver: "onOff")
        PdBase.send(vol, toReceiver: "vol")
    }
}
