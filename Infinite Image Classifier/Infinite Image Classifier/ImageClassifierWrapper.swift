//
//  ImageClassifierWrapper.swift
//  Infinite Image Classifier
//
//  Created by Ryan Du on 1/24/21.
//

import Foundation
import CoreML
import SwiftUI

// Model Prediction Input Type
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class ImageClassifierModelWrapperInput : MLFeatureProvider {

    /// input_2 as color (kCVPixelFormatType_32BGRA) image buffer, 299 pixels wide by 299 pixels high
    var input_2: CVPixelBuffer

    var featureNames: Set<String> {
        get {
            return ["input_2"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input_2") {
            return MLFeatureValue(pixelBuffer: input_2)
        }
        return nil
    }
    
    init(input_2: CVPixelBuffer) {
        self.input_2 = input_2
    }

    convenience init(input_2With input_2: CGImage) throws {
        let __input_2 = try MLFeatureValue(cgImage: input_2, pixelsWide: 299, pixelsHigh: 299, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
        self.init(input_2: __input_2)
    }

    convenience init(input_2At input_2: URL) throws {
        let __input_2 = try MLFeatureValue(imageAt: input_2, pixelsWide: 299, pixelsHigh: 299, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
        self.init(input_2: __input_2)
    }

    func setInput_2(with input_2: CGImage) throws  {
        self.input_2 = try MLFeatureValue(cgImage: input_2, pixelsWide: 299, pixelsHigh: 299, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
    }

    func setInput_2(with input_2: URL) throws  {
        self.input_2 = try MLFeatureValue(imageAt: input_2, pixelsWide: 299, pixelsHigh: 299, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
    }
}


/// Model Prediction Output Type
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class ImageClassifierModelWrapperOutput : MLFeatureProvider {

    /// Source provided by CoreML

    private let provider : MLFeatureProvider


    /// Identity as multidimensional array of floats
    lazy var Identity: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "Identity")!.multiArrayValue
    }()!

    var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    init(Identity: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["Identity" : MLFeatureValue(multiArray: Identity)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class ImageClassifierModelWrapper {
    let model: MLModel
    
    init(mlmodel: MLModel) throws {
        self.model = mlmodel
    }
    
    convenience init(modelURL: URL) {
        do {
            let model = try MLModel(contentsOf: modelURL)
            try self.init(mlmodel: model )
        } catch {
            try! self.init(mlmodel: MLModel() )
        }
        
    }

    /**
        Construct model_2 instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<ImageClassifierModelWrapper, Error>) -> Void) {
        MLModel.__loadContents(of: modelURL, configuration: configuration) { (model, error) in
            if let error = error {
                handler(.failure(error))
            } else if let model = model {
                try? handler(.success(ImageClassifierModelWrapper(mlmodel: model)))
            } else {
                fatalError("SPI failure: -[MLModel loadContentsOfURL:configuration::completionHandler:] vends nil for both model and error.")
            }
        }
    }

    /**
        Make a prediction using the structured interface

        - parameters:
           - input: the input to the prediction as ImageClassifierModelWrapperInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as ImageClassifierModelWrapperOutput
    */
    func prediction(input: ImageClassifierModelWrapperInput) throws -> ImageClassifierModelWrapperOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        - parameters:
           - input: the input to the prediction as ImageClassifierModelWrapperInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as ImageClassifierModelWrapperOutput
    */
    func prediction(input: ImageClassifierModelWrapperInput, options: MLPredictionOptions) throws -> ImageClassifierModelWrapperOutput {
        let outFeatures = try model.prediction(from: input, options:options)
        return ImageClassifierModelWrapperOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        - parameters:
            - input_2 as color (kCVPixelFormatType_32BGRA) image buffer, 299 pixels wide by 299 pixels high

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as ImageClassifierModelWrapperOutput
    */
    func prediction(input_2: CVPixelBuffer) throws -> ImageClassifierModelWrapperOutput {
        let input_ = ImageClassifierModelWrapperInput(input_2: input_2)
        return try self.prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        - parameters:
           - inputs: the inputs to the prediction as [ImageClassifierModelWrapperInput]
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [ImageClassifierModelWrapperOutput]
    */
    func predictions(inputs: [ImageClassifierModelWrapperInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [ImageClassifierModelWrapperOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [ImageClassifierModelWrapperOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  ImageClassifierModelWrapperOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
