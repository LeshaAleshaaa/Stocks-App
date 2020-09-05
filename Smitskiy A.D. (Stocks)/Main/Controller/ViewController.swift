//
//  ViewController.swift
//  Smitskiy A.D. (Stocks)
//
//  Created by Алексей Смицкий on 28.08.2020.
//  Copyright © 2020 Смицкий А.Д. All rights reserved.
//

import UIKit

// MARK: - ViewController

final class ViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private var companyNameLabel: UILabel!
    @IBOutlet private var companyPickerView: UIPickerView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var companySymbolLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!
    @IBOutlet private var priceChangeLabel: UILabel!
    @IBOutlet private var companyLogo: UIImageView!
    @IBOutlet private var companyTitle: UILabel!
    @IBOutlet private var symbolTitle: UILabel!
    @IBOutlet private var priceTitle: UILabel!
    @IBOutlet private var dynamicTitle: UILabel!
    @IBOutlet private var logoTitle: UILabel!
    
    // MARK: - Private properties
    
    private lazy var symbolsArray = [String]()
    private lazy var namesArray = [String]()
    
    var reachability: IReachability = Reachability()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reachability = Reachability()
        setupViews()
        requestQuoteUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        checkInternet()
    }
    
    // MARK: - Private methods
    
    private func checkInternet() {
        if !reachability.isConnectedToNetwork {
            alert(title: Constants.errorMessage, message: Constants.checkInternetError)
        }
    }
    
    private func requestSymbols() {
        
        let urlstring = "https://cloud.iexapis.com/beta/ref-data/symbols?token=\(Constants.urlToken)"
        
        guard let url = URL(string: urlstring) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard
                let data = data,
                error == nil else { return }
            
            do {
                let company = try JSONDecoder().decode([Stocks].self, from: data)
                for index in 0..<company.count {
                    self.symbolsArray.append(company[index].symbol)
                    self.namesArray.append(company[index].name)
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.companyPickerView.reloadAllComponents()
                    let selectedRow = self.companyPickerView.selectedRow(inComponent: 0)
                    let selectedSymbol = self.symbolsArray[selectedRow]
                    self.requestQuote(for: selectedSymbol)
                    self.parseImage(symbol: selectedSymbol)
                }
            }
            catch let error {
                print(error)
            }
        }.resume()
    }
    
    private func parseImage(symbol: String) {
        guard
            let url = URL(string:"https://storage.googleapis.com/iexcloud-hl37opg/api/logos/\(symbol).png"),
            let data = try? Data(contentsOf: url) else { return }
        
        companyLogo.image = UIImage(data: data)
    }
    
    private func requestQuote(for symbol: String) {
        
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(Constants.urlToken)") else { return }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self.parseQuote(from: data)
            } else {
                self.alert(title: Constants.errorMessage, message: Constants.checkInternetError)
            }
        }
        dataTask.resume()
    }
    
    private func parseQuote(from data: Data) {
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double,
                let previousClose = json["previousClose"] as? Double
                else { return alert(title: Constants.errorMessage, message: Constants.checkInternetError) }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.displayStockInfo(companyName: companyName,
                                      companySymbol: companySymbol,
                                      price: price,
                                      priceChange: priceChange,
                                      previousClose: previousClose)
            }
        } catch {
            alert(title: Constants.errorMessage, message: Constants.checkInternetError)
        }
    }
    
    private func displayStockInfo(companyName: String,
                                  companySymbol: String,
                                  price: Double,
                                  priceChange: Double,
                                  previousClose: Double) {
        
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        
        if price > previousClose {
            priceChangeLabel.layer.backgroundColor = Constants.plusColor
            companyNameLabel.layer.cornerRadius = Constants.cornerRadius
        } else if price < previousClose {
            priceChangeLabel.layer.backgroundColor = Constants.minusColor
            companyNameLabel.layer.cornerRadius = Constants.cornerRadius
        } else {
            priceChangeLabel.layer.backgroundColor = Constants.labelsColors
            companyNameLabel.layer.cornerRadius = Constants.cornerRadius
        }
    }
    
    private func requestQuoteUpdate() {
        requestSymbols()
        companyPickerView.reloadAllComponents()
        activityIndicator.startAnimating()
        setEmptyViews()
        priceChangeLabel.textColor = .darkGray
        priceChangeLabel.layer.backgroundColor = Constants.labelsColors
    }
}

// MARK: - UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return Constants.componentsCout
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return namesArray.count
    }
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return namesArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
}

// MARK: - Setups

private extension ViewController {
    
    func setupViews() {
        setPickerView()
        setActivityView()
        setImageView()
        
        setCompanyLabel()
        setSymbolLabel()
        setPriceLabel()
        setDynamicLabel()
        
        setCompanyTitle()
        setSymbolTitle()
        setPriceTitle()
        setDynamicTitle()
        setLogoTitle()
    }
    
    func setPickerView() {
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        companyPickerView.setValue(UIColor.darkGray, forKey: Constants.pickerViewColorTitle)
        companyPickerView.layer.backgroundColor = Constants.labelsColors
        companyPickerView.layer.cornerRadius = Constants.cornerRadius
    }
    
    func setActivityView() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
    }
    
    func setEmptyViews() {
        companyNameLabel.text = Constants.emptyText
        companySymbolLabel.text = Constants.emptyText
        priceLabel.text = Constants.emptyText
        priceChangeLabel.text = Constants.emptyText
        companyLogo.image = .none
    }
    
    func setImageView() {
        companyLogo.contentMode = .scaleAspectFit
        companyLogo.layer.cornerRadius = Constants.cornerRadius
    }
    
    func setCompanyLabel() {
        companyNameLabel.layer.backgroundColor = Constants.labelsColors
        companyNameLabel.layer.cornerRadius = Constants.cornerRadius
    }
    
    func setSymbolLabel() {
        companySymbolLabel.layer.backgroundColor = Constants.labelsColors
        companySymbolLabel.layer.cornerRadius = Constants.cornerRadius
    }
    
    func setPriceLabel() {
        priceLabel.layer.backgroundColor = Constants.labelsColors
        priceLabel.layer.cornerRadius = Constants.cornerRadius
    }
    
    func setDynamicLabel() {
        priceChangeLabel.layer.backgroundColor = Constants.labelsColors
        priceChangeLabel.layer.cornerRadius = Constants.cornerRadius
    }
    
    func setCompanyTitle() {
        companyTitle.layer.backgroundColor = Constants.titleColors
        companyTitle.layer.cornerRadius = Constants.cornerRadius
    }
    
    func setSymbolTitle() {
        symbolTitle.layer.backgroundColor = Constants.titleColors
        symbolTitle.layer.cornerRadius = Constants.cornerRadius
    }
    
    func setPriceTitle() {
        priceTitle.layer.backgroundColor = Constants.titleColors
        priceTitle.layer.cornerRadius = Constants.cornerRadius
    }
    
    func setDynamicTitle() {
        dynamicTitle.layer.backgroundColor = Constants.titleColors
        dynamicTitle.layer.cornerRadius = Constants.cornerRadius
    }
    
    func setLogoTitle() {
        logoTitle.layer.backgroundColor = Constants.titleColors
        logoTitle.layer.cornerRadius = Constants.cornerRadius
    }
}

// MARK: - Constants

extension ViewController {
    
    enum Constants {
        
        static let errorMessage: String = "Ошибка"
        static let checkInternetError = "Проверьте интернет соединение и перезапустите приложение"
        static let pickerViewColorTitle: String = "textColor"
        static let urlToken: String = "pk_3bd7a4477e754a388d37076fec3599a2"
        static let emptyText: String = "-"
        static let cornerRadius: CGFloat = 5
        
        static let titleColors: CGColor = UIColor.darkGray.cgColor
        static let labelsColors: CGColor = UIColor.systemYellow.cgColor
        static let plusColor: CGColor = UIColor.green.cgColor
        static let minusColor: CGColor = UIColor.red.cgColor
        
        static let componentsCout: Int = 1
    }
}
