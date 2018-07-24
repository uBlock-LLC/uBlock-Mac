/*******************************************************************************
 
 µBlock - the most powerful, FREE ad blocker.
 Copyright (C) 2018 The µBlock authors
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see {http://www.gnu.org/licenses/}.
 
 Home: https://github.com/uBlock-LLC/uBlock-Mac
 */

import Cocoa
import SwiftyBeaver
import StoreKit


protocol DonateVCDelegate {
    func donateVC(_ vc: DonateVC, onError errorMsg: String)
    func donateVC(_ vc: DonateVC, onSuccess successMsg: String)
}

class DonateVC: NSViewController {
    @IBOutlet weak var btnDonate: Button!
    @IBOutlet weak var btnDonate799: RadioButton!
    @IBOutlet weak var btnDonate999: RadioButton!
    @IBOutlet weak var btnDonate1499: RadioButton!
    @IBOutlet weak var btnDonate1999: RadioButton!
    @IBOutlet weak var btnDonate2499: RadioButton!
    @IBOutlet weak var btnDonate3499: RadioButton!
    @IBOutlet weak var progress: NSProgressIndicator!
    
    var delegate: DonateVCDelegate?
    
    private var donateQty: Int = 1
    private let numberFormatter = NumberFormatter()
    
    private var donateDataSet: [RadioButton: Constants.Donate]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    private func setup() {
        donateDataSet = [btnDonate799: .donate799,
                         btnDonate999: .donate999,
                         btnDonate1499: .donate1499,
                         btnDonate1999: .donate1999,
                         btnDonate2499: .donate2499,
                         btnDonate3499: .donate3499]
        
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.numberStyle = .currency

        if let selectedDonateAmountButton = selectedDonationButton() {
            donateQty = decideDonateQty(for: selectedDonateAmountButton)
        }

        loadProducts()
    }
    
    private func loadProducts() {
        showProgress(true)
        btnDonate.isEnabled = false
        IAPManager.shared.fetchProducts(with: [Constants.Donate.donate799.rawValue,
                                               Constants.Donate.donate999.rawValue,
                                               Constants.Donate.donate1499.rawValue,
                                               Constants.Donate.donate1999.rawValue,
                                               Constants.Donate.donate2499.rawValue,
                                               Constants.Donate.donate3499.rawValue])
        { (error, products) in
            self.showProgress(false)
            self.btnDonate.isEnabled = self.donateQty > 0
            
            guard let products = products else {
                self.delegate?.donateVC(self, onError: NSLocalizedString("Something went wrong in retrieving donation information. Please try again later.", comment: ""))
                return
            }
            for product in products {
                if let donateButton = self.donateDataSet.filter({ $1.rawValue == product.productIdentifier }).keys.first {
                    self.displayPrice(of: donateButton, from: product)
                }
            }
        }
    }
    
    private func displayPrice(of donateButton: RadioButton, from product: SKProduct) {
        let qty = decideDonateQty(for: donateButton)
        donateButton.title = formattedPrice(of: product, for: qty) ?? "n/a"
    }
    
    private func formattedPrice(of product: SKProduct, for qty: Int) -> String? {
        numberFormatter.locale = product.priceLocale
        numberFormatter.currencySymbol = product.priceLocale.currencySymbol
        
        let newPrice = product.price.multiplying(by: NSDecimalNumber(value: qty))
        return numberFormatter.string(from: newPrice)
    }
    
    private func showProgress(_ show: Bool) {
        progress.isHidden = !show
        if show {
            progress.startAnimation(nil)
        } else {
            progress.stopAnimation(nil)
        }
        enableDonationAmountButtons(!show)
    }
    
    private func enableDonationAmountButtons(_ enable: Bool) {
        for (donateButton, _) in donateDataSet {
            donateButton.isEnabled = enable
        }
    }
    
    private func decideDonateQty(for sender: RadioButton) -> Int {
        return 1
    }
    
    private func selectedDonationButton() -> RadioButton? {
        for (donateButton, _) in donateDataSet {
            if (donateButton.state == .on) {
                return donateButton
            }
        }
        return nil
    }
    
    @IBAction func donateAmountClick(_ sender: RadioButton) {
        sender.state = sender.state == .on ? .on : .off
        donateQty = sender.state == .off ? 0 : self.decideDonateQty(for: sender)
        btnDonate.isEnabled = sender.state == .on
    }
    
    @IBAction func donateClick(_ sender: Any) {
        btnDonate.isEnabled = false
        guard donateQty > 0, let donationIdentifier = donateDataSet[selectedDonationButton()!]?.rawValue else {
            btnDonate.isEnabled = true
            self.delegate?.donateVC(self, onError: NSLocalizedString("Please select donation amount", comment: ""))
            return
        }
        // 1. Purchase
        showProgress(true)
        IAPManager.shared.purchase(product: donationIdentifier, qty: donateQty) { (error, purchase) in
            
            // 2. Handle purchase error
            if let error = error {
                self.showProgress(false)
                self.btnDonate.isEnabled = true
                switch error {
                case .other(let err):
                    SwiftyBeaver.error("Error in purchase: \(err)")
                    self.delegate?.donateVC(self, onError: err.localizedDescription)
                case .paymentFailed(let skErrorCode):
                    SwiftyBeaver.error("Payment failed error: \(skErrorCode)")
                    let errorMsg = "\(NSLocalizedString("Payment is failed due to", comment: "")) \(skErrorCode)"
                    self.delegate?.donateVC(self, onError: errorMsg)
                case .cancelledPurchase:
                    SwiftyBeaver.debug("User has cancelled the purchase")
                default:
                    SwiftyBeaver.debug("Remaining error cases aren't used for purchase.")
                }
                return
            }
            
            // 3. Receipt validation
            IAPManager.shared.validateReceipt({ (error, receipt) in
                // 4. Handle receipt validation error
                self.showProgress(false)
                self.btnDonate.isEnabled = true
                if let error = error {
                    switch error {
                    case .other(let err):
                        self.delegate?.donateVC(self, onError: err.localizedDescription)
                    case .receiptValidationFailed(let errMessage):
                        self.delegate?.donateVC(self, onError: errMessage)
                    default:
                        SwiftyBeaver.error("Unknow receipt validation error: \(error)")
                    }
                    
                    return
                }
                
                // 5. Purchase successful, give feedback to user
                self.delegate?.donateVC(self, onSuccess: NSLocalizedString("Thank you for supporting uBlock!", comment: ""))
            })
        }
    }
}
