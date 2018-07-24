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

import SwiftyStoreKit
import StoreKit
import SwiftyBeaver
import Alamofire

enum IAPError: Error {
    case emptyProductIds
    case invalidIdentifiers(Set<String>)
    case other(Error) // in other cases
    case cancelledPurchase // in case of user cancelled the purchase
    case paymentFailed(SKError.Code) // in case of .clientInvalid, .paymentNotAllowed
    case receiptValidationFailed(String)
    
    case restorePurchaseFailed
}

class IAPManager: NSObject {
    static let shared: IAPManager = IAPManager()
    
    private override init() {}
    
    func initialize() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                case .failed, .purchasing, .deferred:
                    break
                }
            }
        }
    }
    
    func fetchProducts(with identifiers:Set<String>, completion: @escaping (_ error: IAPError?, _ products: Set<SKProduct>?)->Void) {
        if identifiers.count == 0 {
            completion(IAPError.emptyProductIds, nil)
            return
        }
        
        SwiftyStoreKit.retrieveProductsInfo(identifiers) { result in
            if let error = result.error {
                SwiftyBeaver.error("IAPManager: Error \(result.error.debugDescription)")
                completion(IAPError.other(error), nil)
                return
            }
            
            if !result.invalidProductIDs.isEmpty {
                completion(IAPError.invalidIdentifiers(result.invalidProductIDs), nil)
                return
            }
            
            completion(nil, result.retrievedProducts)
        }
    }
    
    func restorePurchases(_ completion: @escaping (_ error: IAPError?, _ restoredPurchases: [Purchase]?)->Void) {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            for purchase in results.restoredPurchases where purchase.needsFinishTransaction {
                SwiftyStoreKit.finishTransaction(purchase.transaction)
            }
            
            if results.restoreFailedPurchases.count > 0 {
                SwiftyBeaver.error("Restore Failed: \(results.restoreFailedPurchases)")
                DispatchQueue.main.async { completion(IAPError.restorePurchaseFailed, nil) }
            } else if results.restoredPurchases.count > 0 {
                SwiftyBeaver.debug("Restore Success: \(results.restoredPurchases)")
                DispatchQueue.main.async { completion(nil, results.restoredPurchases) }
            } else {
                SwiftyBeaver.debug("Nothing to Restore")
                DispatchQueue.main.async { completion(nil, []) }
            }
        }
    }
    
    func purchase(product identifier:String, qty: Int = 1, completion: @escaping (_ error: IAPError?, _ purchase: PurchaseDetails?)->Void) {
        SwiftyStoreKit.purchaseProduct(identifier, quantity: qty, atomically: true) { result in
            switch result {
            case .success(let purchase):
                SwiftyBeaver.debug("IAPManager: Purchase Success \(purchase.productId)")
                completion(nil, purchase)
            case .error(let error):
                switch error.code {
                case .unknown:
                    // Unknown error. Please contact support
                    DispatchQueue.main.async { completion(.other(error), nil) }
                case .clientInvalid, .paymentNotAllowed:
                    // Not allowed to make the payment
                    // The device is not allowed to make the payment
                    DispatchQueue.main.async { completion(.paymentFailed(error.code), nil) }
                case .paymentCancelled:
                    DispatchQueue.main.async { completion(.cancelledPurchase, nil) }
                case .paymentInvalid:
                    // The purchase identifier was invalid
                    DispatchQueue.main.async { completion(.invalidIdentifiers([identifier]), nil) }
                }
            }
        }
    }
    
    func validateReceipt(_ completion: @escaping (_ error: IAPError?, _ receipt: ReceiptInfo?)->Void ) {
        let receiptData = SwiftyStoreKit.localReceiptData
        let receiptString = receiptData?.base64EncodedString(options: [])
        guard let url = URL(string: "\(Constants.API_URL)\(Constants.Api.validateReceipt)" ) else {
            completion(IAPError.other(Constants.uBlockError.invalidApiUrl), nil)
            return
        }
        SwiftyBeaver.debug("IAPManager: \(url.absoluteString)")
        Alamofire.request(url, method: .post, parameters: ["receipt": receiptString ?? ""])
            .validate()
            .responseJSON { (response) in
                guard response.result.isSuccess else {
                    completion(IAPError.other(response.result.error!), nil)
                    return
                }
                do {
                    let receiptInfo = try response.result.unwrap() as? ReceiptInfo
                    if receiptInfo?["success"] as? Int ?? 0 == 0 {
                        let error = receiptInfo?["error"] as? [String: String]
                        completion(IAPError.receiptValidationFailed(error?["message"] ?? NSLocalizedString("Unknown error occurred", comment: "")), nil)
                    } else {
                        completion(nil, receiptInfo)
                    }
                } catch {
                    SwiftyBeaver.error("IAPManager: Exception: \(error)")
                    completion(IAPError.other(error), nil)
                }
        }
    }
    
}
