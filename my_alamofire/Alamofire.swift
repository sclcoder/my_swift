//
//  Alamofire.swift
//  my_swift
//
//  Created by sunchunlei on 2022/11/7.
//

import Dispatch
import Foundation
#if canImport(FoundationNetworking)
@_exported import FoundationNetworking
#endif

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.3)
#error("Alamofire doesn't support Swift versions below 5.3.")
#endif

public let My_AF = Session.default


let version = "5.6.2"
