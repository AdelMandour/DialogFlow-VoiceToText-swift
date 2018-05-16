
import UIKit

class ResultNavigationController: UINavigationController {
    var response: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resultViewController = self.viewControllers.first! as! ResultViewController
        resultViewController.response = self.response
    }
}
