import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class WeatherViewController: UIViewController, CLLocationManagerDelegate, changeCityDelegate{
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "cdc521b1575e114e1669def21544bef7"
    let KELVIN_TO_CELSIUS : Double = 273.15

    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    
    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //TODO:Set up the location manager here.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        //request user for location use
        locationManager.requestWhenInUseAuthorization()
        // let's start picking up the GPS position
        locationManager.startUpdatingLocation()
        
    }
    
    
    
    //MARK: - Networking
    /***************************************************************/
    func getWeatherData(url: String, parameters: [String : String]){
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON(){
            response in
            if response.result.isSuccess{
                let weatherDataJSON : JSON = JSON (response.result.value!)
                self.updateWeatherData(json: weatherDataJSON)
            }
            else{
                print("Error! \(response.result.error!)")
                self.cityLabel.text = "Connection Issue"
            }
        }
    }

    //MARK: - JSON Parsing
    /***************************************************************/
   
    func updateWeatherData(json : JSON){
        //thanks to swifty json
        if let tempResult = json["main"]["temp"].double {
            weatherDataModel.temperature = Int(tempResult - KELVIN_TO_CELSIUS)
            weatherDataModel.city        = json["name"].stringValue
            weatherDataModel.condition   = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            print("weatherDataModel.city == \(weatherDataModel.city)")
        }
        else{
            weatherDataModel.city = "weather unavailable"
            print(json)
        }
            updateUIWithWeatherData()
    }


    //MARK: - UI Updates
    /***************************************************************/
    
    
    func updateUIWithWeatherData(){
        temperatureLabel.text = String(weatherDataModel.temperature)
        cityLabel.text = weatherDataModel.city
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
    }
    
    
    
    
    
    //- Location Manager Delegate Methods
    /***************************************************************/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        //if it finds the gps location
        let location = locations[locations.count-1]
        //check if location is valid
        if location.horizontalAccuracy > 0{
            //if valid, then stop updating
            locationManager.stopUpdatingLocation()
            print ("Longitude: \(location.coordinate.longitude), latitude: \(location.coordinate.latitude)")
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            //format needed by the OpenWeatherAPI
            let params : [String : String] = ["lat": latitude, "lon": longitude, "appid" : APP_ID]
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //if fails to get the location
        print(error)
        cityLabel.text = "Location Unavailable!"
    }
    
    
    

    
    //MARK: - Change City Delegate methods
    /***************************************************************/
    
    
    func userEnteredANewCityName(cityName: String) {
            let params : [String : String] = ["q": cityName, "appid" : APP_ID]
            print("Getting weather Data for \(cityName)")
            getWeatherData(url:WEATHER_URL, parameters: params)
    }
    
    
    //passing the delegate
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName"{
            let destinationVC = segue.destination as! ChangeCityViewController
            destinationVC.delegate = self
            print("delegate set")
        }
    }
}
