//
//  URLRequest+Alamofire.swift
//
//  Copyright (c) 2019 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension URLRequest {
    /**
        为URLRequest添加一个method属性(主要用来替代内部的httpMethod属性)
        httpMethod是URLRequest的方法，是字符串类型
        get方法：将httpMethod的值装换为HTTPMethod类型
        set方法：将HTTPMethod类型的原始值(字符串类型)的值设置到httpMethod
     */
    
    /// Returns the `httpMethod` as Alamofire's `HTTPMethod` type.
    public var method: HTTPMethod? {
        get { httpMethod.flatMap(HTTPMethod.init) }
        set { httpMethod = newValue?.rawValue }
    }

    public func validate() throws {
        if method == .get, let bodyData = httpBody {
            throw AFError.urlRequestValidationFailed(reason: .bodyDataInGETRequest(bodyData))
        }
    }
}
