//
//  CurrentWeather.swift
//  Weather_APP (iOS)
//
//  Created by Lai Wei on 2021-04-05.
//

import Foundation
import Alamofire
import SwiftyJSON

class CurrentWeather {
    
  static  var shared: CurrentWeather = {
        let weather = CurrentWeather()
        return weather
    }()
    
    func getCurrentWeather() {
        let locate_URL = "https://api.weatherbit.io/v2.0/current?lat=35.7796&lon=-78.6382&key=d076bec442804dae9bff6d383f9951e6&include=minutely"
        
        AF.request(locate_URL).responseJSON{ response in
            let result = response.result
           
            switch result {
            case .failure :
                print("no result found")
            case .success :
               print(result)
            }
            
        }
    }
}
