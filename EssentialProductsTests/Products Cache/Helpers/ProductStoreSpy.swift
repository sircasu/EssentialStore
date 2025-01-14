//
//  ProductStoreSpy.swift
//  EssentialProductsTests
//
//  Created by Matteo Casu on 29/11/24.
//

import Foundation
import EssentialProducts

public class ProductStoreSpy: ProductStore {
            
    enum ReceivedMessages: Equatable {
        case deleteCachedProducts
        case insert([LocalProductItem], Date)
        case retrieve
    }
    
    var insertions = [(items: [LocalProductItem], timestamp: Date)]()
    var receivedMessages: [ReceivedMessages] = [ReceivedMessages]()
    
    var deletionCompletions: [DeletionCompletion] = [DeletionCompletion]()
    var insertionsCompletion: [InsertionCompletion] = [InsertionCompletion]()
    var retrievalCompletion: [RetrievalCompletion] = [RetrievalCompletion]()
    
    public func deleteCachedProducts(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedProducts)
    }
    
    func completeWithError(error: Error, at index: Int = 0) {
        deletionCompletions[index](.failure(error))
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](.success(()))
    }
    
    public func insert(_ items: [LocalProductItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertions.append((items, timestamp))
        receivedMessages.append(.insert(items, timestamp))
        insertionsCompletion.append(completion)
    }
    
    func completeInsertWithError(error: Error, at index: Int = 0) {
        insertionsCompletion[index](.failure(error))
    }
    
    func completeInsertSuccessfully(at index: Int = 0) {
        insertionsCompletion[index](.success(()))
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        retrievalCompletion.append(completion)
        receivedMessages.append(.retrieve)
    }
    
    public func completeRetrievalWithError(error: Error, at index: Int = 0) {
        retrievalCompletion[index](.failure(error))
    }
    
    public func completeRetrievalWithEmptyItems(at index: Int = 0) {
        retrievalCompletion[index](.success(.none))
    }
    
    public func completeRetrieval(with products: [LocalProductItem], timestamp: Date, at index: Int = 0) {
        retrievalCompletion[index](.success(CachedProducts(products: products, timestamp: timestamp)))
    }
}
