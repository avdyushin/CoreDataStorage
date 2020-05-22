//
//  LinuxMain.swift
//
//  Created by Grigory Avdyushin on 21/05/2020.
//  Copyright © 2020 Grigory Avdyushin. All rights reserved.
//
import XCTest

import CoreDataStorageTests

var tests = [XCTestCaseEntry]()
tests += CoreDataStorageTests.allTests()
XCTMain(tests)
