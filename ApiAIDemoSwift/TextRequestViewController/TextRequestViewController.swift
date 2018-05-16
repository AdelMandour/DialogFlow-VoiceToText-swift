

import UIKit
import Speech
@available(iOS 10.0, *)
class TextRequestViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet var textField: UITextField? = nil
    @IBOutlet weak var microphoneButton: UIButton!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer!
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))  //1
        microphoneButton.isEnabled = false  //2ƒ
        speechRecognizer?.delegate = self  //3
            SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
                var isButtonEnabled = false
                switch authStatus {  //5
                case .authorized:
                    isButtonEnabled = true
                case .denied:
                    isButtonEnabled = false
                    print("User denied access to speech recognition")
                case .restricted:
                    isButtonEnabled = false
                    print("Speech recognition restricted on this device")
                case .notDetermined:
                    isButtonEnabled = false
                    print("Speech recognition not yet authorized")
                }
                OperationQueue.main.addOperation() {
                    self.microphoneButton.isEnabled = isButtonEnabled
                }
            }
    }
    @IBAction func sendText(_ sender: UIButton)
    {
        let hud = MBProgressHUD.showAdded(to: self.view.window!, animated: true)
        
        self.textField?.resignFirstResponder()
        
        let request = ApiAI.shared().textRequest()
        
        if let text = self.textField?.text {
            request?.query = [text]
        } else {
            request?.query = [""]
        }
        
        request?.setCompletionBlockSuccess({[unowned self] (request, response) -> Void in
            let resultNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as! ResultNavigationController
            let json = response as! [String:Any]
            let fulfillment = json["result"] as! [String:Any]
            let answer = fulfillment["fulfillment"] as! [String:Any]
            resultNavigationController.response = answer["speech"] as? String
            
            self.present(resultNavigationController, animated: true, completion: nil)
            
            hud.hide(animated: true)
            }, failure: { (request, error) -> Void in
                hud.hide(animated: true)
        });
        
        ApiAI.shared().enqueue(request)
    }
    @IBAction func microphoneTapped(_ sender: UIButton) {
        DispatchQueue.main.async {
            if self.audioEngine.isRunning {
                self.audioEngine.inputNode?.removeTap(onBus: 0)
                self.audioEngine.inputNode?.reset()
                self.audioEngine.stop()
                print("audioEngineStop")
                self.recognitionRequest?.endAudio()
                print("recognition")
                self.microphoneButton.isEnabled = false
                self.microphoneButton.setTitle("Start Recording", for: .normal)
            } else {
                self.startRecording()
                self.microphoneButton.setTitle("Stop Recording", for: .normal)
            }
        }
       /* if audioEngine.isRunning {
            audioEngine.stop()
            print("audioEngineStop")
            recognitionRequest?.endAudio()
            print("recognition")
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }*/
    }
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
      
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.microphoneButton.isEnabled = true
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        textView.text = "Say something, I'm listening!"
    }
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
}
