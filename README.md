# BedrockService

This library is a work in progress, feel free to open an issue, but do not use it in your projects just yet. 

## Getting started with BedrockService

1. Set-up your `Package.swift`

First add dependencies: 
```bash
swift package add-dependency https://github.com/sebsto/swift-bedrock-library.git --branch main
swift package add-target-dependency BedrockService TargetName
```

Next up add `platforms` configuration after `name`

```swift
platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18)],
```

Your `Package.swift` should now look something like this: 
```swift
import PackageDescription

let package = Package(
    name: "ProjectName",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18)],
    dependencies: [
        .package(url: "https://github.com/sebsto/swift-bedrock-library.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "TargetName",
            dependencies: [
                .product(name: "BedrockService", package: "swift-bedrock-library"),
            ]
        )
    ]
)
```

2. Import the BedrockService and BedrockTypes

```swift 
import BedrockService
import BedrockTypes
```

3. Initialize the BedrockService

Choose what Region to use, whether to use AWS SSO authentication instead of standard credentials and pass a logger. If no region is passed it will default to `.useast1`, if no logger is provided a default logger with the name `bedrock.service` is created. The log level will be set to the environment variable `BEDROCK_SERVICE_LOG_LEVEL` or default to `.trace`. If `useSSO` is not defined it will default to `false` and use the standard credentials for authentication.

```swift 
let bedrock = try await BedrockService(
    region: .uswest1,
    logger: logger,
    useSSO: true
) 
```

4. List the available models

Use the `listModels()` function to test your set-up. This function will return an array of `ModelSummary` objects, each one representing a model supported by Amazon Bedrock. The ModelSummaries that contain a `BedrockModel` object are the models supported by BedrockService. 

```swift
let models = try await bedrock.listModels()
```

## How to generate text using the InvokeModel API

Choose a BedrockModel that supports text generation, you can verify this using the `hasTextModality` function. when calling the `completeText` function you can provide some inference parameters: 

- `maxTokens`: The maximum amount of tokens that the model is allowed to return
- `temperature`: Controls the randomness of the model's output
- `topP`: Nucleus sampling, this parameter controls the cumulative probability threshold for token selection
- `topK`: Limits the number of tokens the model considers for each step of text generation to the K most likely ones
- `stopSequences`: An array of strings that will cause the model to stop generating further text when encountered

The function returns a `TextCompletion` object containg the generated text.

```swift
let model = .anthropicClaude3Sonnet

guard model.hasTextModality() else {
    print("\(model.name) does not support text completion")
}

let textCompletion = try await bedrock.completeText(
    "Write a story about a space adventure",
    with: model
)
```

Optionally add inference parameters.

```swift
let textCompletion = try await bedrock.completeText(
    "Write a story about a space adventure",
    with: model,
    maxTokens: 1000,
    temperature: 0.7,
    topP: 0.9,
    topK: 250,
    stopSequences: ["THE END"]
)
```

Note that the minimum, maximum and default values for each parameter are model specific and defined when the BedrockModel is created. Some parameters might not be supported by certain models.

## How to generate an image using the InvokeModel API

Choose a BedrockModel that supports image generation - you can verify this using the `hasImageModality` and the `hasTextToImageModality` function. The `generateImage` function allows you to create images from text descriptions with various optional parameters:

- `prompt`: Text description of the desired image
- `negativePrompt`: Text describing what to avoid in the generated image
- `nrOfImages`: Number of images to generate
- `cfgScale`: Classifier free guidance scale to control how closely the image follows the prompt
- `seed`: Seed for reproducible image generation
- `quality`: Parameter to control the quality of generated images
- `resolution`: Desired image resolution for the generated images

The function returns an ImageGenerationOutput object containing an array of generated images in base64 format.

```swift
let model: BedrockModel = .nova_canvas

guard model.hasImageModality(),
      model.hasTextToImageModality() else {
    print("\(model.name) does not support image generation")
}

let imageGeneration = try await bedrock.generateImage(
    "A serene landscape with mountains at sunset",
    with: model,
)
```

Optionally add inference parameters.

```swift
let imageGeneration = try await bedrock.generateImage(
    "A serene landscape with mountains at sunset",
    with: model,
    negativePrompt: "dark, stormy, people",
    nrOfImages: 3,
    cfgScale: 7.0,
    seed: 42,
    quality: .standard,
    resolution: ImageResolution(width: 100, height: 100)
)
```

Note that the minimum, maximum and default values for each parameter are model specific and defined when the BedrockModel is created. Some parameters might not be supported by certain models.

## How to generate image variations using the InvokeModel API
Choose a BedrockModel that supports image variations - you can verify this using the `hasImageVariationModality` and the `hasImageVariationModality` function. The `generateImageVariation` function allows you to create variations of an existing image with these parameters:

- `images`: The base64-encoded source images used to create variations from
- `negativePrompt`: Text describing what to avoid in the generated image
- `similarity`: Controls how similar the variations will be to the source images
- `nrOfImages`: Number of variations to generate
- `cfgScale`: Classifier free guidance scale to control how closely variations follow the original image
- `seed`: Seed for reproducible variation generation
- `quality`: Parameter to control the quality of generated variations
- `resolution`: Desired resolution for the output variations

This function returns an `ImageGenerationOutput` object containing an array of generated image variations in base64 format. Each variation will maintain key characteristics of the source images while introducing creative differences.

```swift
let model: BedrockModel = .nova_canvas

guard model.hasImageVariationModality(),
      model.hasImageVariationModality() else {
    print("\(model.name) does not support image variations")
}

let imageVariations = try await bedrock.generateImageVariation(
    images: [base64EncodedImage],
    prompt: "A dog drinking out of this teacup",
    with: model
)
```

Optionally add inference parameters.

```swift
let imageVariations = try await bedrock.generateImageVariation(
    images: [base64EncodedImage],
    prompt: "A dog drinking out of this teacup",
    with: model,
    negativePrompt: "Cats, worms, rain",
    similarity: 0.8,
    nrOfVariations: 4,
    cfgScale: 7.0,
    seed: 42,
    quality: .standard,
    resolution: ImageResolution(width: 100, height: 100)
)
```

Note that the minimum, maximum and default values for each parameter are model specific and defined when the BedrockModel is created. Some parameters might not be supported by certain models.

## How to chat using the Converse API

### Text prompt

```swift
let model: BedrockModel = .nova_lite

guard model.hasConverseModality() else {
    print("\(model.name) does not support converse")
}

var reply = try await bedrock.converse(
    with: model,
    prompt: "Tell me about rainbows"
)

print("Assistant: \(reply)")

reply = try await bedrock.converse(
    with: model,
    prompt: "Do you think birds can see them too?",
    history: history
)

print("Assistant: \(reply)")
```

Optionally add inference parameters. 

```swift
var reply = try await bedrock.converse(
    with: model,
    prompt: "Tell me about rainbows",
    history: history,
    maxTokens: 1024,
    temperature: 0.2,
    topP: 0.8,
    stopSequences: ["END", "STOP", "<assistant>"],
    systemPrompts: ["Do not pretend to be human", "Never talk about goats", "You like puppies"]
    )
```


### Vision

```swift
let model: BedrockModel = .nova_lite

guard model.hasConverseModality(.vision) else {
    print("\(model.name) does not support converse")
}

let reply = try await bedrock.converse(
    with model: model,
    prompt: "Can you tell me about this plant?",
    imageFormat: .jpeg,
    imageBytes: base64EncodedImage
)

print("Assistant: \(reply)")
```


Optionally add inference parameters. 

```swift
var reply = try await bedrock.converse(
    with model: model,
    prompt: "Can you tell me about this plant?",
    imageFormat: .jpeg,
    imageBytes: base64EncodedImage,
    history: history,
    temperature: 1
    )
```

### Tools

```swift
let model: BedrockModel = .nova_lite

// verify that the model supports tool usage
guard model.hasConverseModality(.toolUse) else {
    print("\(model.name) does not support converse tools")
}

// define the inputschema for your tool
let inputSchema = JSON([
    "type": "object",
    "properties": [
        "sign": [
            "type": "string",
            "description": "The call sign for the radio station for which you want the most popular song. Example calls signs are WZPZ and WKRP."
        ]
    ],
    "required": [
        "sign"
    ]
])

// create a Tool object
let tool = Tool(name: "top_song", inputSchema: inputSchema, description: "Get the most popular song played on a radio station.")

// pass a prompt and the tool to converse
var reply = try await bedrock.converse(
    with model: model,
    prompt: "What is the most popular song on WZPZ?",
    tools: [tool]
)

print("Assistant: \(reply)")  
// The reply will be similar to this: "I need to use the \"top_song\" tool to find the most popular song on the radio station WZPZ. I will input the call sign \"WZPZ\" into the tool to get the required information."
// The last message in the history will contain the tool use request

if reply.hasToolUse() {
    let id = reply.toolUse.id
    let name = reply.toolUse.name
    let input = reply.toolUse.input

    // Logic to use the tool here
    
    let toolResult = ToolResultBlock("The Best Song Ever", id: id)

    // Send the toolResult back to the model
    reply = try await bedrock.converse(
    with: model,
    history: history,
    tools: [tool],
    toolResult: toolResult
    )
}

print("Assistant: \(reply)")
// The final reply will be similar to: "The most popular song currently played on WZPZ is \"The Best Song Ever\". If you need more information or have another request, feel free to ask!"
```

### Make your own `Message`

Alternatively use the `converse` function that does not take a `prompt`, `toolResult` or `image` and construct the `Message` yourself. 

```swift
// Message with prompt
let replyMessage = try await bedrock.converse(
    with: model,
    conversation: [Message("What day of the week is it?")]
)

// Optionally add inference parameters
let replyMessage = try await bedrock.converse(
    with: model,
    conversation: [Message("What day of the week is it?")],
    maxTokens: 512,
    temperature: 1,
    topP: 0.8,
    stopSequences: ["THE END"],
    systemPrompts: ["Today is Wednesday, make sure to mention that."]
)

// Message with an image and prompt
let replyMessage = try await bedrock.converse(
    with: model,
    conversation: [Message("What is in the this teacup?", imageFormat: .jpeg, imageBytes: base64EncodedImage)],
)

// Message with toolResult
let replyMessage = try await bedrock.converse(
    with: model,
    conversation: [Message(toolResult)],
    tools: [toolA, toolB]
)
```

## How to add a BedrockModel

### Text

-- Under Construction --

### Image

-- Under Construction --

### Converse

To add a new model that only needs the ConverseModality, simply use the `StandardConverse` and add the correct [inferece parameters](https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters.html) and [supported converse features](https://docs.aws.amazon.com/bedrock/latest/userguide/conversation-inference-supported-models-features.html).

```swift
extension BedrockModel {
    public static let new_bedrock_model = BedrockModel(
        id: "family.model-id-v1:0",
        name: "New Model Name",
        modality: StandardConverse(
            parameters: ConverseParameters(
                temperature: Parameter(.temperature, minValue: 0, maxValue: 1, defaultValue: 0.3),
                maxTokens: Parameter(.maxTokens, minValue: 1, maxValue: nil, defaultValue: nil),
                topP: Parameter(.topP, minValue: 0.01, maxValue: 0.99, defaultValue: 0.75),
                stopSequences: StopSequenceParams(maxSequences: nil, defaultValue: []),
                maxPromptSize: nil
            ),
            features: [.textGeneration, .systemPrompts, .document, .toolUse]
        )
    )
}
```

If the model also implements other modalities you might need to create you own `Modality` and make sure it conforms to `ConverseModality` by implementing the `getConverseParameters` and `getConverseFeatures` functions. Note that the `ConverseParameters` can be extracted from `TextGenerationParameters` by using the public initializer.

```swift
struct ModelFamilyModality: TextModality, ConverseModality {
    func getName() -> String { "Model Family Text and Converse Modality" }

    let parameters: TextGenerationParameters
    let converseFeatures: [ConverseFeature]
    let converseParameters: ConverseParameters

    init(parameters: TextGenerationParameters, features: [ConverseFeature] = [.textGeneration]) {
        self.parameters = parameters
        self.converseFeatures = features

        // public initializer to extract `ConverseParameters` from `TextGenerationParameters`
        self.converseParameters = ConverseParameters(textGenerationParameters: parameters) 
    }

    // ...
}
```
