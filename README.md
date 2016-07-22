# CRUDE-Futures

[![CI Status](http://img.shields.io/travis/Jason Welch/CRUDE-Futures.svg?style=flat)](https://travis-ci.org/Jason Welch/CRUDE-Futures)
[![Version](https://img.shields.io/cocoapods/v/CRUDE-Futures.svg?style=flat)](http://cocoapods.org/pods/CRUDE-Futures)
[![License](https://img.shields.io/cocoapods/l/CRUDE-Futures.svg?style=flat)](http://cocoapods.org/pods/CRUDE-Futures)
[![Platform](https://img.shields.io/cocoapods/p/CRUDE-Futures.svg?style=flat)](http://cocoapods.org/pods/CRUDE-Futures)

Your data models can be easily Created, Read, Updated, Deleted, and Enumerated from a remote server simply by inheriting from CRUDE's various protocols. CRUDE-Futures leverages [BrightFutures](http://cocoapods.org/pods/BrightFutures) to asychronously load your data models, making requests with the help of [Alamofire](http://cocoapods.org/pods/Alamofire) and mapping the returned JSON with [SwiftyJSON](http://cocoapods.org/pods/SwiftyJSON). Please note, CRUDE will not work for API calls returning XML instead of JSON.

## Requirements

Crude-Futures currently requires the following pods...
* [Alamofire](http://cocoapods.org/pods/Alamofire) version 3.4 or greater
* [SwiftyJSON](http://cocoapods.org/pods/SwiftyJSON) version 2.3 or greater
* [BrightFutures](http://cocoapods.org/pods/BrightFutures) version 4.1 or greater
* [Result](http://cocoapods.org/pods/Result) version 2.0 or greater

## Installation

CRUDE-Futures is NOT YET available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CRUDE-Futures', :git => 'https://github.com/JasonCanCode/CRUDE-Futures.git'
```
## Getting Started

The first and most important step is setting up CRUDE for use in your app. `import CRUDE_FUTURES` in your `AppDelegate`, then call `configure` within `application(application: didFinishLaunchingWithOptions:)`. For example:

```swift
CRUDE.configure(baseURL: "https://mysite.com/api", headers: kDefaultHeaders)
```

If you would like CRUDE to do some kind of logging whenever API calls are made, you can provide a `CRUDELog` block. This can be done through a variable...

```swift
let myLogger: CRUDELog = { method, response in
    print("CRUDE request \(method) \(response.request?.URLString)")
}

CRUDE.configure(baseURL: "https://mysite.com/api", headers: kDefaultHeaders, requestLoggingBlock: myLogger)
```

...or by providing the block at the end of your configure call...

```swift
CRUDE.configure(baseURL: "https://mysite.com/api", headers: kDefaultHeaders) { method, response in
    print("CRUDE request \(method) \(response.request?.URLString)")
}
```

## Mappable Models

While CRUDE is intended for use with structs, it can be used with classes and even managed objects (to an extent).

The first thing you need to do is import `CRUDE_Futures` and `SwiftyJSON`. Then you state how you intend to you use your model by applying any number of protocols. For a read-only model, you might just use `CRUDEReadable` or maybe add `CRUDEEnumeratable` if you want to retrieve a bunch at a time. Data entities can be created and destroyed through the use of `CRUDECreatable` and `CRUDEDeletable`. If you want modify your entities and demand that the server conforms to the new reality you have forged, you can do so with `CRUDEUpdatable`.

All of these different protocols conform to `CRUDERequestable`, which require a model to set its `path` string to let CRUDE where those models can typically be found. For example `static let path = "people"` will tell CRUDE to send requests to "https://mysite.com/api/people". Optionally, a model can also set an `objectKey` string whenever the returning JSON has encased all the precious attributes in dictionary with a single key. If you do not set this in your model, it will default to `nil`.

In order to easily convert some JSON into a nifty model, it needs to be `JSONConvertable`. This means it can be initialized by passing it a `JSON` object. Here is what a Person model object might look like:

```swift
struct Person: CRUDEReadable {
    static let path: String = "person"

    let id: Int
    let firstName: String
    let lastName: String
    let favoriteColor: String?

    init(_ json: JSON) {
        id = json["id_Number"].intValue
        firstName = json["first_name"].stringValue
        lastName = json["last_name"].stringValue
        favoriteColor = json["favorite_color"].string
    }
}
```
NOTE: While you don't need the `id` property for creating and enumerating models, it is required for `CRUDEReadable`, `CRUDEUpdatable`, and `CRUDEDeletable`. This is to automatically infer url paths. For example, requesting a person with the id number `12345` would go out to "https://mysite.com/api/people/12345". You can override this path if you like (explained later) but the `id` requirement remains.

Yes, you have to do all that one to one mapping but it can pay off. Let's say you have a `Household` entity that has several people. It can map its `people` attribute like so:
```swift
    people = json["people"].array?.map { Person($0) }.sort { $0.firstName < $1.firstName} ?? []
```
Look at that! We even sorted them by their first names, all on one line! If you are going to making all of your requests and mapping through `Household` and not `Person`, you can have `Person` just adhere to `JSONConvertable`.

If you have a model that is going to be doing all the things, you can use `CRUDEMappable` in lieu of the listing out all five.

## The Write Way

For updating your remote database with an entity, it will need to be `JSONAttributable`. This means it has an inverse mapping of its properties.

```swift
var attributes: [String : AnyObject?] {
    return [
        "id_Number": id,
        "first_name": firstName,
        "last_name": lastName,
        "favorite_color": favoriteColor
    ]
}
```

Notice that `attributes` contains optional objects. `JSONAttributable` provides a computed property called `validAttributes` that will automatically remove attributes that don't have values, like potentially `favoriteColor`. In the example of the `Household` model, an entity would contain `"people": people.map { $0.validAttributes }` when computing its `attributes`.

## Getting the Okay

`Okay` is an empty object whose sole purpose is the have something to return `.onSuccess`. This is used any model that is `CRUDEDeletable`, since there shouldn't be any mappable JSON coming back from a .DELETE request.

If you want to make a request and you don't care what is coming back from the server you can use `CRUDE.requestForSuccess`, which will also return an `Okay`.

## Making the Call

So what does an API call look like? Some protocols provide static requests, some instance requests, and some both. For instance if you want to get a new person with an id number of 12345...
```swift
Person.readFromServerWithId(12345)
```
...or if you have that person and you just want to make sure you have to most up-to-date version...
```swift
self.person.readFromServer()
```

Keep in mind that CRUDE does not mutate entities when making requests. Rather it provides a new entity upon completion. Asynchronous calls are handled using the BrightFutures syntax, so a retrieval of the newest version of a person might look like this:

```swift
self.person.readFromServer().onSuccess { person in
    self.person = person
}.onFailure { error in
    print(error)
}.onComplete { _ in
    self.stopLoading()
}
```

As you can see, `.onComplete` provides a raw `Result` but you can dump that if you just want to use this block for clean up code.

The mappable protocols provide convenience requests for you the explicitly call based on your intent, but you have access the underlying requests that they use. The most basic method is simply `request` which will give you a Future with a JSON object.

```swift
CRUDE.request(.GET, CRUDE.baseURL + "person/\(self.person.id)")
```

If you would like the control of a direct request but don't want the hassle of converting that JSON into an entity, you can use `requestObject` for one or `requestObjectsArray` for a collection. Just make sure you cast the returning Future with the desired object.

```swift
let request = CRUDE.requestObject(.GET, CRUDE.baseURL + "person/\(self.person.id)", parameters: queryItems) as Future<[Person], NSError>

request.onSuccess { people in
    self.household.people = people
}
```

## Directing Traffic

CRUDE assumes a simple API structure in which requests relating to a model are made. If your baseURL is "https://mysite.com/api/" then requests for `Person` objects should look like this:

* Create => POST request to "https://mysite.com/api/people"
* Read => GET request to "https://mysite.com/api/people/12345"
* Update => PUT request to "https://mysite.com/api/people/12345"
* Delete => DELETE request to "https://mysite.com/api/people/12345"
* Enumerate => GET request to "https://mysite.com/api/people"

As mentioned earlier, all this is done automatically with the use of `path`. However, your API may not be quite so simple. Perhaps an update goes to "https://mysite.com/api/households/people/12345" and retrieving a specific person comes from "https://mysite.com/api/person/12345". Each of the five protocols has a specific path that you can override for requests of that type. So in this scenario, you would set a value for `updatePath` and `readPath`, letting `path` handle the other three cases.

## Super Controlling

If you want to be able to control the the request traffic itself, you can use a `CRUDERequest` objects instead of the `CRUDE` static methods. NOTE: You still need to have configured `CRUDE`.

Initialize a `CRUDERequest` instance the same way you would use the request function. The `urlString` is a must, with the option to provide `parameters` and/or `headers`. To execute the request, you have three options very similar to the three basic `CRUDE` static functions...

* `makeRequestForJSON` instead of `request`
* `makeRequestForObject<T: JSONConvertable>` instead of `requestObject<T: JSONConvertable>`
* `makeRequestForObjectsArray<T: JSONConvertable>` instead of `requestObjectsArray<T: JSONConvertable>`

While the request is running, you can use `pauseRequest()` to take a break. Then either `resumeRequest()` later or give up on it and `cancelRequest()`.

## Author

Jason Welch, jwelch@groupon.com

## License

CRUDE-Futures is available under the MIT license. See the LICENSE file for more info.
