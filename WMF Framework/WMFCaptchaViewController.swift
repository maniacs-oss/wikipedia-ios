
import UIKit

// Presently it is assumed this view controller will be used only as a
// child view controller of another view controller.

extension UIStackView {
    fileprivate var wmf_isCollapsed: Bool {
        set {
            for subview in arrangedSubviews {
                subview.isHidden = newValue
            }
        }
        get {
            for subview in arrangedSubviews {
                if !subview.isHidden {
                    return false
                }
            }
            return true
        }
    }
}

@objc public protocol WMFCaptchaViewControllerDelegate{
    func captchaReloadPushed(_ sender: AnyObject)
    func captchaSolutionChanged(_ sender: AnyObject, solutionText: String?)
    func captchaSiteURL() -> URL
    func captchaKeyboardReturnKeyTapped()
    func captchaHideSubtitle() -> Bool
}

public class WMFCaptcha: NSObject {
    @objc let captchaID: String
    @objc let captchaURL: URL
    @objc init(captchaID:String, captchaURL:URL) {
        self.captchaID = captchaID
        self.captchaURL = captchaURL
    }
    static func captcha(from requests: [[String : AnyObject]]) -> WMFCaptcha? {
        guard
            let captchaAuthenticationRequest = requests.first(where:{$0["id"]! as! String == "CaptchaAuthenticationRequest"}),
            let fields = captchaAuthenticationRequest["fields"] as? [String : AnyObject],
            let captchaId = fields["captchaId"] as? [String : AnyObject],
            let captchaInfo = fields["captchaInfo"] as? [String : AnyObject],
            let captchaIdValue = captchaId["value"] as? String,
            let captchaInfoValue = captchaInfo["value"] as? String,
            let captchaURL = URL(string: captchaInfoValue)
            else {
                return nil
        }
        return WMFCaptcha(captchaID: captchaIdValue, captchaURL: captchaURL)
    }
}

class WMFCaptchaViewController: UIViewController, UITextFieldDelegate, Themeable {

    @IBOutlet fileprivate var captchaImageView: UIImageView!
    @IBOutlet fileprivate var captchaTextFieldTitleLabel: UILabel!
    @IBOutlet fileprivate var captchaTextField: ThemeableTextField!
    @IBOutlet fileprivate var stackView: UIStackView!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: WMFAuthLinkLabel!
    @IBOutlet fileprivate var infoButton: UIButton!
    @IBOutlet fileprivate var refreshButton: UIButton!

    @objc public weak var captchaDelegate: WMFCaptchaViewControllerDelegate?
    fileprivate let captchaResetter = WMFCaptchaResetter()
    
    fileprivate var theme = Theme.standard

    @objc var captcha: WMFCaptcha? {
        didSet {
            guard let captcha = captcha else {
                captchaTextField.text = nil
                stackView.wmf_isCollapsed = true
                return;
            }
            stackView.wmf_isCollapsed = false
            captchaTextField.text = ""
            refreshImage(for: captcha)
            if let captchaDelegate = captchaDelegate {
                subTitleLabel.isHidden = captchaDelegate.captchaHideSubtitle()
            }
        }
    }
    
    @objc var solution:String? {
        get{
            guard
                let captchaSolution = captchaTextField.text,
                captchaSolution.count > 0
                else {
                    return nil
            }
            return captchaTextField.text
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == captchaTextField {
            guard let captchaDelegate = captchaDelegate else {
                assertionFailure("Expected delegate not set")
                return true
            }
            captchaDelegate.captchaKeyboardReturnKeyTapped()
        }
        return true
    }
    
    fileprivate func refreshImage(for captcha: WMFCaptcha) {
        guard let fullCaptchaImageURL = fullCaptchaImageURL(from: captcha.captchaURL) else {
            assertionFailure("Unable to determine fullCaptchaImageURL")
            return
        }
        captchaImageView.wmf_setImage(with: fullCaptchaImageURL, detectFaces: false, onGPU: false, failure: { (error) in
            
        }) { 
            
        }
    }
    
    public func captchaTextFieldBecomeFirstResponder() {
        // Reminder: captchaTextField is private so this vc maintains control over the captcha solution.
        captchaTextField.becomeFirstResponder()
    }

    fileprivate func fullCaptchaImageURL(from captchaURL: URL) -> URL? {
        guard let components = URLComponents(url: captchaURL, resolvingAgainstBaseURL: false) else {
            assertionFailure("Could not extract url components")
            return nil
        }
        return components.url(relativeTo: captchaBaseURL())
    }
    
    fileprivate func captchaBaseURL() -> URL? {
        guard let captchaDelegate = captchaDelegate else {
            assertionFailure("Expected delegate not set")
            return nil
        }
        let captchaSiteURL = captchaDelegate.captchaSiteURL()
        guard var components = URLComponents(url: captchaSiteURL, resolvingAgainstBaseURL: false) else {
            assertionFailure("Could not extract url components")
            return nil
        }
        components.queryItems = nil
        guard let url = components.url else{
            assertionFailure("Could not extract url")
            return nil
        }
        return url
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        captchaDelegate?.captchaSolutionChanged(self, solutionText:sender.text)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let captchaDelegate = captchaDelegate else{
            assertionFailure("Required delegate is unset")
            return
        }
        
        assert(stackView.wmf_firstArrangedSubviewWithRequiredNonZeroHeightConstraint() == nil, "\n\nAll stackview arrangedSubview height constraints need to have a priority of < 1000 so the stackview can collapse the 'cell' if the arrangedSubview's isHidden property is set to true. This arrangedSubview was determined to have a required height: \(String(describing: stackView.wmf_firstArrangedSubviewWithRequiredNonZeroHeightConstraint())). To fix reduce the priority of its height constraint to < 1000.\n\n")
        
        

        captcha = nil
        captchaTextFieldTitleLabel.text = WMFLocalizedString("field-captcha-title", value:"Enter the text you see above", comment: "Title for captcha field")
        captchaTextField.placeholder = WMFLocalizedString("field-captcha-placeholder", value:"CAPTCHA text", comment: "Placeholder text shown inside captcha field until user taps on it")
        titleLabel.text = WMFLocalizedString("account-creation-captcha-title", value:"CAPTCHA security check", comment: "Title for account creation CAPTCHA interface")
        
        // Reminder: used a label instead of a button for subtitle because of multi-line string issues with UIButton.
        subTitleLabel.strings = WMFAuthLinkLabelStrings(dollarSignString: WMFLocalizedString("account-creation-captcha-cannot-see-image", value:"Can't see the image? %1$@", comment: "Text asking the user if they cannot see the captcha image. %1$@ is the message {{msg-wm|Wikipedia-ios-account-creation-captcha-request-account}}"), substitutionString: WMFLocalizedString("account-creation-captcha-request-account", value:"Request account.", comment: "Text for link to 'Request an account' page."))
        subTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(requestAnAccountTapped(_:))))
    
        subTitleLabel.isHidden = (captcha == nil) || captchaDelegate.captchaHideSubtitle()

        view.wmf_configureSubviewsForDynamicType()
        
        apply(theme: theme)
    }
    
    @objc func requestAnAccountTapped(_ recognizer: UITapGestureRecognizer) {
        wmf_openExternalUrl(URL.init(string: "https://en.wikipedia.org/wiki/Wikipedia:Request_an_account"))
    }
    
    @IBAction fileprivate func infoButtonTapped(withSender sender: UIButton) {
        wmf_openExternalUrl(URL.init(string: "https://en.wikipedia.org/wiki/Special:Captcha/help"))
    }

    @IBAction fileprivate func refreshButtonTapped(withSender sender: UIButton) {
        captchaDelegate?.captchaReloadPushed(self)
                
        let failure: WMFErrorHandler = {error in }
        
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedString("account-creation-captcha-obtaining", value:"Obtaining a new CAPTCHA...", comment: "Alert shown when user wants a new captcha when creating account"), sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
        
        self.captchaResetter.resetCaptcha(siteURL: captchaBaseURL()!, success: { result in
            guard let previousCaptcha = self.captcha else {
                assertionFailure("If resetting a captcha, expect to have a previous one here")
                return
            }
            
            let previousCaptchaURL = previousCaptcha.captchaURL
            let previousCaptchaNSURL = previousCaptchaURL as NSURL
            
            let newCaptchaID = result.index
            
            // Resetter only fetches captchaID, so use previous captchaURL changing its wpCaptchaId.
            let newCaptchaURL = previousCaptchaNSURL.wmf_url(withValue: newCaptchaID, forQueryKey:"wpCaptchaId")
            let newCaptcha = WMFCaptcha.init(captchaID: newCaptchaID, captchaURL: newCaptchaURL)
            self.captcha = newCaptcha
            
        }, failure:failure)
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        
        titleLabel.textColor = theme.colors.primaryText
        captchaTextFieldTitleLabel.textColor = theme.colors.secondaryText
        subTitleLabel.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        captchaTextField.apply(theme: theme)
        view.tintColor = theme.colors.link
    }
}
