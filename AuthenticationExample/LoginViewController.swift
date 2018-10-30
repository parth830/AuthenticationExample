
import UIKit
import CoreData

struct KeychainConfiguration {
  static let serviceName = "TouchMeIn"
  static let accessGroup: String? = nil
  
}

class LoginViewController: UIViewController {

  // MARK: Properties
  var managedObjectContext: NSManagedObjectContext?
  var passwordItems: [KeychainPasswordItem] = []
  let createButtonTag = 0
  let loginButtonTag = 1
  let faceMe = BioMetricIDAuth()

  // MARK: - IBOutlets
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var usernameTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var createInfoLabel: UILabel!  
  @IBOutlet weak var faceIDButton: UIButton!
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let hasLogin = UserDefaults.standard.bool(forKey: "hasLoginKey")
    
    if hasLogin {
      loginButton.setTitle("Login", for: .normal)
      loginButton.tag = loginButtonTag
      createInfoLabel.isHidden = true
    } else {
      loginButton.setTitle("Create", for: .normal)
      loginButton.tag = createButtonTag
      createInfoLabel.isHidden = false
    }
    
    if let storedUsername = UserDefaults.standard.value(forKey: "username") as? String {
      usernameTextField.text = storedUsername
    }
    
    faceIDButton.isHidden = !faceMe.canEvaluatePolicy()
    
    switch faceMe.bioMetricType() {
    case .faceID:
      faceIDButton.setImage(UIImage(named: "FaceIcon"), for: .normal)
    default: 
      faceIDButton.setImage(UIImage(named: "Touch-icon-lg"),  for: .normal)
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let touchBool = faceMe.canEvaluatePolicy()
    if touchBool {
      FaceIDButtonAction()
    }
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: - Alert
  private func showLoginFailedAlert() {
    let alertView = UIAlertController(title: "Login Problem",
                                      message: "Wrong username or password.",
                                      preferredStyle:. alert)
    let okAction = UIAlertAction(title: "Foiled Again!", style: .default)
    alertView.addAction(okAction)
    present(alertView, animated: true)
  }
  
  // MARK: - Check Login credentials
  func checkLogin(username: String, password: String) -> Bool {
    guard username == UserDefaults.standard.value(forKey: "username") as? String else {
      return false
    }
    
    do {
      let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                              account: username,
                                              accessGroup: KeychainConfiguration.accessGroup)
      let keychainPassword = try passwordItem.readPassword()
      return password == keychainPassword
    } catch {
      fatalError("Error reading password from keychain - \(error)")
    }
  }
  
  // MARK: - Handle Face ID Authentication
  func FaceIDButtonAction() {
    faceMe.authenticate() { [weak self] message in
      if let message = message {
        // if the completion is not nil show an alert
        
        Alert.showAlert(on: self!, with: "Authentocation Error", message: message)
      } else {
        // 3
        self?.performSegue(withIdentifier: "dismissLogin", sender: self)
      }
    }
  }
}

// MARK: - IBActions
extension LoginViewController {

  @IBAction func loginAction(sender: UIButton) {
    
    guard let newAccountName = usernameTextField.text,
      let newPassword = passwordTextField.text,
      !newAccountName.isEmpty,
      !newPassword.isEmpty else {
        Alert.showAlert(on: self, with: "Login Fail", message: "Empty Usename or Password")
        return
    }
    
    usernameTextField.resignFirstResponder()
    passwordTextField.resignFirstResponder()
    
    if sender.tag == createButtonTag {
      let hasLoginKey = UserDefaults.standard.bool(forKey: "hasLoginKey")
      if !hasLoginKey && usernameTextField.hasText {
        UserDefaults.standard.setValue(usernameTextField.text, forKey: "username")
      }
      
      do {
        // This is a new account, create a new keychain item with the account name.
        let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                                account: newAccountName,
                                                accessGroup: KeychainConfiguration.accessGroup)
        
        // Save the password for the new item.
        try passwordItem.savePassword(newPassword)
      } catch {
        fatalError("Error updating keychain - \(error)")
      }
      
      UserDefaults.standard.set(true, forKey: "hasLoginKey")
      loginButton.tag = loginButtonTag
      performSegue(withIdentifier: "dismissLogin", sender: self)
    } else if sender.tag == loginButtonTag {
      if checkLogin(username: newAccountName, password: newPassword) {
        performSegue(withIdentifier: "dismissLogin", sender: self)
      } else {
        Alert.showAlert(on: self, with: "Login Fail", message: "Wrong Username or Password")
      }
    }
  }
}
