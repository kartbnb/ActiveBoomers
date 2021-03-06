//
//  WeatherAPI.swift
//  ActiDiabet
//
//  Created by 佟诗博 on 14/4/20.
//  Copyright © 2020 Shibo Tong. All rights reserved.
//

import Foundation
import UIKit
import MapKit

/// This file is for collecting current weather

var weatherString: String = ""

struct Weather {
    var main: String
    var temp: Int
    var city: String
    var image: String
    var coordinate: CLLocation
}

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}

extension Weather {
    init?(json: [String: Any]) {
        guard let cityName = json["name"] as? String else {
            print("name key miss")
            return nil
        }
        guard let weatherArray = json["weather"] as? [[String: Any]] else {
             print("weather key miss")
            return nil
        }

        
        guard let main = weatherArray.first else {
             print("array key miss")
            return nil
        }
        guard let weather = main["main"] as? String else {
             print("main key miss")
            return nil
        }
        guard let imageCode = main["icon"] as? String else {
            print("icon key miss")
            return nil
        }
        guard let tempJson = json["main"] as? [String: Any] else {
             print("main key miss")
            return nil
        }
        guard let temp = tempJson["temp"] as? Double else {
             print("temp key miss")
            return nil
        }
        guard let coord = json["coord"] as? [String: Any] else {
            print("coord key miss")
            return nil
        }
        guard let lat = coord["lat"] as? Double else {
            print("lat key miss")
            return nil
        }
        guard let lon = coord["lon"] as? Double else {
            print("long key miss")
            return nil
        }
        weatherString = imageCode
        self.main = weather
        self.temp = Int(temp - 273.15)
        self.city = cityName
        self.image = imageCode
        self.coordinate = CLLocation(latitude: lat, longitude: lon)
    }
}

class WeatherAPI {
    
    // api key here
    private let key = "7fc2a15a9f888ed016b6f19867dccfa3"
    
    func getCurrentWeather(weatherView: WeatherView) {
        // get zip code of user
        let zipCode = UserDefaults.standard.object(forKey: "zipcode") as? String
        if let zip = zipCode {
            let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?zip=\(zip),AU&appid=\(key)")
            
            if let url = url {
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    if let data = data {
                        self.performdata(data: data, weatherView: weatherView)
                    } else {
                        print("111")
                    }
                }.resume()
                
            } else {
                
            }
        } else {
            
        }
    }
    
    // get coordinate with zip code and show map center
    func getCoordinate(mapView: MapViewController) {
        let zipCode = UserDefaults.standard.object(forKey: "zipcode") as? String
        if let zip = zipCode {
            let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?zip=\(zip),AU&appid=\(key)")
            if let url = url {
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    if let data = data {
                        let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        if let json = json {
                            if let dictionary = json as? [String: Any] {
                                let weather = Weather(json: dictionary)
                                DispatchQueue.main.async {
                                    mapView.setMapView(center: weather?.coordinate)
                                }
                            }
                        }
                    } else {
                        print("no data for weather")
                    }
                }.resume()
            }
        }
    }
    
    func performdata(data: Data, weatherView: WeatherView) {
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        if let json = json {
            if let dictionary = json as? [String: Any] {
                let weather = Weather(json: dictionary)
                DispatchQueue.main.async {
                    weatherView.setupWeather(weather: weather)
                }
                
            }
        }
    }
    
    
}
