
import Foundation
import LocalAuthentication

enum BioMetricType {
  case none
  case touchID
  case faceID
}

class BioMetricIDAuth {
  
  let context = LAContext()
  var loginReason = "Logging in with Face ID"
  
  func canEvaluatePolicy() -> Bool {
    return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
  }
  
  // MARK : - Check devcie support face ID or Touch ID
  func bioMetricType() -> BioMetricType {
    let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    switch context.biometryType {
    case .none:
      return .none
    case .touchID:
      return .touchID
    case .faceID:
      return .faceID
    }
  }
  
  // MARK: - Authentication of USer BioMetrics 
  func authenticate(completion: @escaping (String?) -> Void) {
    
    guard canEvaluatePolicy() else {
      completion("Touch ID  or Face ID not available")
      return
    }
    
    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: loginReason) { (success, evaluateError) in
      if success {
        DispatchQueue.main.async {
          completion(nil)
        }
      } else {
        let message: String
        
        switch evaluateError {
        case LAError.authenticationFailed?:
          message = "There was a problem verifying your identity."
        case LAError.userCancel?:
          message = "You pressed cancel."
        case LAError.userFallback?:
          message = "You pressed password."
        case LAError.biometryNotAvailable?:
          message = "Face ID/Touch ID is not available."
        case LAError.biometryNotEnrolled?:
          message = "Face ID/Touch ID is not set up."
        case LAError.biometryLockout?:
          message = "Face ID/Touch ID is locked."
        default:
          message = "Face ID/Touch ID may not be configured"
        }
        completion(message)
      }
    }
  }
}


















