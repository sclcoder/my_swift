//: [Previous](@previous)

import Foundation

var greeting = "Hello, playground"

import Foundation

// associatedtype
protocol Food {
    
}

protocol Animal {
    associatedtype F : Food
    func eat(_ food: F)
}

struct Meat: Food{
    
}

struct Grass: Food{
    
}

struct Tiger: Animal{
    typealias F = Meat
    func eat(_ food: Meat) {
        print("eat \(food)")
    }
    
//    public func eat(_ food: Food) {
//        if let meat = food as? Meat{
//            print("eat \(meat)")
//        } else {
//            fatalError("Tiger can only meat")
//        }
//    }
}


struct Rabbit: Animal{
    func eat(_ food: Grass) {
        print("eat \(food)")
    }
}

let meat = Meat()

Tiger().eat(meat)

let grass = Grass()
Rabbit().eat(grass)


func isDangerous(animal: any Animal) -> Bool{
    if animal is Tiger{
        return true
    } else {
        return false
    }
}

isDangerous(animal: Tiger())

isDangerous(animal: Rabbit())


/// 泛型
func isDangerous2<T: Animal>(animal: T) -> Bool{
    if animal is Tiger{
        return true
    } else {
        return false
    }
}


//: [Next](@next)
