//
//  CacheProductsUseCaseTests.swift
//  EssentialProductsTests
//
//  Created by Matteo Casu on 22/11/24.
//

import XCTest
import EssentialProducts

final class CacheProductsUseCaseTests: XCTestCase {
    
    func test_init_doesNotRequestToDeleteCache() {

        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestToDeleteCache() {
        
        let (sut, store) = makeSUT()
        
        sut.save([uniqueItem(id: 1)]) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedProducts])
    }
    
    func test_save_doesNotRequestToInsertCacheOnDeletionError() {
        
        let (sut, store) = makeSUT()
        let items = [uniqueItem(id: 1), uniqueItem(id: 2)]
        
        sut.save(items) { _ in }
        store.completeWithError(error: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedProducts])
    }
    
    func test_save_doesRequestToInsertCacheWithTimestampOnDeletionSuccess() {
        
        let timestamp = Date.init()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [uniqueItem(id: 1), uniqueItem(id: 2)]
        
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
      
        XCTAssertEqual(store.receivedMessages, [.deleteCachedProducts, .insert(items, timestamp)])
    }
        
    func test_save_deliverErrorOnDeletingError() {
        
        let (sut, store) = makeSUT()
        let error = anyNSError()

        expect(sut, toCompleteWithError: error, when: {
            store.completeWithError(error: error)
        })
    }

    func test_save_deliverErrorOnInsertionError() {
        
        let (sut, store) = makeSUT()
        let error = anyNSError()

        expect(sut, toCompleteWithError: error, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertWithError(error: error)
        })
    }
    
    func test_save_succeedsOnSuccessInsertion() {
        
        let (sut, store) = makeSUT()
        expect(sut, toCompleteWithError: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertSuccessfully()
        })
    }
    
    func test_save_doesNotDeliverErrorOnDeletionErrorAfterSUTHasBeendeallocated() {
        
        let store = ProductStoreSpy()
        var sut: LocalProductsLoader? = LocalProductsLoader(store: store, currentDate: Date.init)
        
        var receivedMessages = [Error?]()
        sut?.save([uniqueItem(id: 1)]) { receivedMessages.append($0) }
        
        sut = nil
        
        store.completeWithError(error: anyNSError())
        
        XCTAssertTrue(receivedMessages.isEmpty)
    }
    
    func test_save_doesNotDeliverErrorOnInsertionErrorAfterSUTHasBeendeallocated() {
        
        let store = ProductStoreSpy()
        var sut: LocalProductsLoader? = LocalProductsLoader(store: store, currentDate: Date.init)
        
        var receivedMessages = [Error?]()
        sut?.save([uniqueItem(id: 1)]) { receivedMessages.append($0) }
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertWithError(error: anyNSError())
        
        XCTAssertTrue(receivedMessages.isEmpty)
    }
    
    // MARK: - Helpers
    
    private class ProductStoreSpy: ProductStore {
        
        enum ReceivedMessages: Equatable {
            case deleteCachedProducts
            case insert([ProductItem], Date)
        }
        
        var insertions = [(items: [ProductItem], timestamp: Date)]()
        var receivedMessages: [ReceivedMessages] = [ReceivedMessages]()
        
        var deletionCompletions: [DeletionCompletion] = [DeletionCompletion]()
        var insertionsCompletion: [InsertionCompletion] = [InsertionCompletion]()
        
        func delete(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedProducts)
        }
        
        func insert(_ items: [ProductItem], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertions.append((items, timestamp))
            receivedMessages.append(.insert(items, timestamp))
            insertionsCompletion.append(completion)
        }
        
        func completeWithError(error: Error?, at index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func completeInsertWithError(error: Error?, at index: Int = 0) {
            insertionsCompletion[index](error)
        }
        func completeInsertSuccessfully(at index: Int = 0) {
            insertionsCompletion[index](nil)
        }
    }
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalProductsLoader, ProductStoreSpy) {
        let store = ProductStoreSpy()
        let sut = LocalProductsLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(store, file: file, line: line)
        
        return (sut: sut, store: store)
    }
    
    private func expect(_ sut: LocalProductsLoader, toCompleteWithError error: NSError?, when action: @escaping () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Waid for load completion")
        let items = [uniqueItem(id: 1), uniqueItem(id: 2)]

        var receivedError: Error?
        sut.save(items) {
            receivedError = $0
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, error, file: file, line: line)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "test", code: 0)
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://example.com/")!
    }
    
    private func uniqueItem(id: Int) -> ProductItem {
        return ProductItem(id: 1, title: "any title", price: 12.99, description: "a description", category: "a category", image: anyURL(), rating: ProductRatingItem(rate: 4.3, count: 24))
    }
}
