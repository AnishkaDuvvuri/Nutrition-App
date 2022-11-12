//
//  ContentView.swift
//  Nutrition App
//
//  Created by Anishka Duvvuri on 9/4/22.
//

import SwiftUI
import Alamofire
import SwiftyJSON

struct NutritionPredict: View {
    @State var prediction: String = "I don't know yet"
    @State var params: Parameters = [:]
    @State var age: Float = 20
    let minAge = 10
    let maxAge = 100
    @State var genderChoice = "male"

    let genders = [ //lowercase vs uppercase gives a dinstinction between user input and values for AI
        "male":"Male",
        "female":"Female",
        "nonbinary":"Nonbinary",
    ]
    
    @State var breakfast = ""
    @State var lunch = ""
    @State var dinner = ""
    @State var snacks = ""
    
    @State var totalCalories=0
    @State var totalProteins = 0
    @State var totalFat=0
    @State var totalCarbs=0

    @State var activityLevel = 0
    let activityLevels = ["sedentary", "moderate", "active"]

    let uploadURL = "https://4c9kil1hsi.execute-api.us-east-1.amazonaws.com/Predict/448d1e79-95c2-4535-bada-41843c7d7279"

    var body: some View {
        NavigationView {
            Form { //2 sections - 1 for input, other for output
                Section(header: Text("Inputs")) {

                    VStack {
                        Text("Age: \(age, specifier: "%.0f")")
                        HStack {
                            Image(systemName: "minus")
                            Slider(value: $age.onChangeOf(updateFoodConsumed), in: 10...100)
                            Image(systemName: "plus")
                        }.foregroundColor(Color.green) //everything in Hstack is green
                    }
                    Picker("Gender", selection: $genderChoice.onChangeOf(updateFoodConsumed)) {
                        ForEach(genders.sorted(by:<), id: \.key) { //user picks Female, genderchoice set to female
                            Text($1)
                        }
                    }
                    TextField("What did you eat for breakfast?", text:$breakfast,
                              onCommit: {updateFoodConsumed()})
                    TextField("What did you eat for lunch?", text:$lunch,
                              onCommit: {updateFoodConsumed()})
                    TextField("What did you eat for dinner?", text:$dinner,
                              onCommit: {updateFoodConsumed()})
                    TextField("What did you eat for snacks?", text:$snacks,
                              onCommit: {updateFoodConsumed()})

                    Stepper(value: $activityLevel.onChangeOf(updateFoodConsumed), in: 0...2) {
                        Text("Activity Level: \(activityLevels[activityLevel])")
                    }
                }.accentColor(Color.green)

                Section {
                    HStack {
                        Text("Prediction:").font(.largeTitle)
                        Spacer() //occupies all space it can
                        Text(prediction)
                    }
                }
            }.navigationBarTitle(Text("Nutrition level"),displayMode: .inline) //yellow bar
        }.onAppear(perform: updateFoodConsumed) //prediction will be "i don't know"
    }
    
    func updateFoodConsumed() {
        print("Just got the call to updateFoodConsumed()") //prints in debug window (console)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) //resignFirstResponder removes the keyboard --> can see the whole app again
        debugPrint("Calling the Nutrition service")
        accumulateNutritionInfo()
    }
    
    func accumulateNutritionInfo() {
        // We have information about the various breakfast, lunch, and other choices.
        // Combine to get overall nutrition information.
        debugPrint("Calling the accumulateNutritionInfo service")
        totalCalories=0
        totalProteins = 0
        totalFat=0
        totalCarbs=0
        
        addOneMeal(breakfast) //calling addOneMeal for each meal
        addOneMeal(lunch)
        addOneMeal(dinner)
        addOneMeal(snacks)
    }
    
    func addOneMeal(_ st:String) {
        let s=st.filter { !$0.isWhitespace }
        if(s.count<2){
            return
        }
        
        let nutritionURL="https://spoonacular-recipe-food-nutrition-v1.p.rapidapi.com/recipes/guessNutrition?title="+s
        //tells server what food items there were; will return calories, carbs, proteins, fats (ex: "Cal, carbs, protein, fat is 466,47,25,21"), line 149
        print("Calling addOneMeal with \(nutritionURL) for \(s)")
        let headers:HTTPHeaders = [
            "X-RapidAPI-Host": "spoonacular-recipe-food-nutrition-v1.p.rapidapi.com",
                "X-RapidAPI-Key": "ed2e57f8cemsh3b6b32df5faee12p135030jsnd59648c04075"
            ]
        AF.request(nutritionURL, method: .get, headers:headers).responseJSON { response in
            // calls API for input
            //debugPrint("AF.Response:",response)
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                //debugPrint("Initial value is ",value," with json ",json)
                let cal=JSON(json["calories"])["value"].stringValue
                let car=JSON(json["carbs"])["value"].stringValue
                let pro=JSON(json["protein"])["value"].stringValue
                let fat=JSON(json["fat"])["value"].stringValue
                debugPrint("Cal, carbs, protein, fat is \(cal),\(car),\(pro),\(fat)")
                totalCalories += Int(cal) ?? 0
                totalCarbs += Int(car) ?? 0
                totalProteins += Int(pro) ?? 0
                totalFat += Int(fat) ?? 0
                debugPrint("TOTALCal, carbs, protein, fat is \(totalCalories),\(totalCarbs),\(totalProteins),\(totalFat)")
                predictAI() //all values added, predict AI called
            default:
                print("In default")
            }
        }
    }
        
    func predictionMessage(_ s: String)->String{
        switch s{
            case "low": return "Over nutrioned"
            case "medium": return "Balanced"
            case "high": return "Malnourished"
            default: return "suprised"
        }
        //return s
    }

    func predictAI() {
        print("Just got the call to PredictAI()")
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        params["Activity"] = String(activityLevel)
        params["Calories"]=String(totalCalories)
        params["Carbs"]=String(totalCarbs)
        params["Protein"]=String(totalProteins)
        params["Fat"]=String(totalFat)

        debugPrint("Calling the AI service with parameters=",params)
        let uploadURL = "https://askai.aiclub.world/109d9241-c273-44d3-a8a1-52b575060647"
        self.prediction="Calling AI"
             //right click, see where the code comes from
        AF.request(uploadURL, method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { response in
            //debugPrint("AF.Response:",response)
            switch response.result {
            case .success(let value):
                var json = JSON(value)
                //debugPrint("Initial value is ",value)
                //debugPrint("Initial JSON is ",json)
                let body = json["body"].stringValue
                //debugPrint("Initial Body is ",body)
                json = JSON.init(parseJSON: body)
                debugPrint("Second JSON is ",json)
                let predictedLabel = json["predicted_label"].stringValue
                //debugPrint("Predicted label equals",predictedLabel)
                let s = predictionMessage(predictedLabel)
                self.prediction=String(s)
            case .failure(let error):
                print("\n\n Request failed with error: \(error)")
            }
        }
        
    }

    init() {
        // UI look-and-feel
        UINavigationBar.appearance().backgroundColor = .yellow
    }
}

extension Binding {
    func onChangeOf(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler()
            }
        )
    }
}

struct NutritionPredict_Previews: PreviewProvider {
    static var previews: some View {
        NutritionPredict()
    }
}
