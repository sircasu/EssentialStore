//
//  EssentialProductsCacheIntegrationTests.swift
//  EssentialProductsCacheIntegrationTests
//
//  Created by Matteo Casu on 08/01/25.
//

import XCTest
import EssentialProducts

final class EssentialProductsCacheIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for completion")
        sut.load { result in
            
            switch result {
            case let .success(products):
                XCTAssertEqual(products, [])
            case let .failure(error):
                XCTFail("Expected success got \(error) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() {
        
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let products = uniqueItems().model
        
        let saveExp = expectation(description: "Wait for save completion")
        sutToPerformSave.save(products) { saveError in
            
            XCTAssertNil(saveError, "Expect to save products correctly")
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)
        
        let loadExp = expectation(description: "Wait for load completion")
        sutToPerformLoad.load { result in
            
            switch result {
            case let .success(loadedProducts):
                XCTAssertEqual(loadedProducts, products)
            case let .failure(error):
                XCTFail("Expected success got \(error) instead")
            }
            loadExp.fulfill()
        }
        wait(for: [loadExp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> LocalProductsLoader {
        let storeBundle = Bundle(for: CoreDataProductStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataProductStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalProductsLoader(store: store, currentDate: Date.init)
        trackForMemoryLeak(store, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectoryURL().appendingPathComponent("\(type(of: self)).store)")
    }
    
    private func cachesDirectoryURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}