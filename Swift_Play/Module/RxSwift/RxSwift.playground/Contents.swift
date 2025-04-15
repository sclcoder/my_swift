import RxSwift

struct Student {
    let name: String
    let scores: [Int]  // 一个学生有多个成绩
}

let students = [
    Student(name: "Alice", scores: [80, 90, 85]),
    Student(name: "Bob", scores: [70, 65]),
    Student(name: "Charlie", scores: [95, 88, 92])
]


// 只使用map - 得到的是成绩数组的数组
let scoresArrays = students.map { $0.scores }
print(scoresArrays)
// 输出: [[80, 90, 85], [70, 65], [95, 88, 92]]


// 使用flatMap - 自动扁平化为一个数组
let allScores = students.flatMap { $0.scores }
print(allScores)
// 输出: [80, 90, 85, 70, 65, 95, 88, 92]




let studentObservables = Observable.from(students)

// 使用map - 得到的是Observable<[Int]>
let mapped = studentObservables.map { $0.scores }
// 订阅会收到: [80,90,85] → [70,65] → [95,88,92]
mapped.subscribe(onNext: {array in
       print(array)
})


// 使用flatMap - 得到的是Observable<Int>
let flatMapped = studentObservables.flatMap { student in
    return Observable.from(student.scores)
}
// 订阅会收到: 80 → 90 → 85 → 70 → 65 → 95 → 88 → 92
flatMapped.subscribe(onNext: {score in
        print(score)
})
