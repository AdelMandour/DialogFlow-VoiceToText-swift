
 

import UIKit

class ResultViewController: UIViewController {
    @IBOutlet fileprivate var textView: UITextView? = nil
    
    var response: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.textView?.text = self.response
    }

    @IBAction func done(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}
