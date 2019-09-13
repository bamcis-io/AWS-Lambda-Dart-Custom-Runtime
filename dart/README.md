# AWS Lambda Dart 2.5 Custom Runtime

## Intro
This project is a proof of concept for building a custom runtime for Dart. It dynamically executes your .dart file. 

## Usage
To utilize the code, bundle the bootstrap file and the dart folder into a .zip and upload as a layer for AWS Lambda. Specify this layer in your Lambda function for its custom runtime. The handler format in your function must be:

    <path to your dart file without the extension>.<library name>.<class name>.<function name>

So, for example: `mydartfile.TestLibrary.TestClass.TestFunction`

This project includes the `dart` command line executable (Dart VM) from the official Dart SDK for version 2.5.0 to make getting started easy, but feel free to bundle whichever version of the Dart VM you want in the layer that provides the custom runtime.

### Lambda Event Data Serialization
Because of the lack of dynamic serialization libraries in Dart, the input to the Lambda function and its output must be a `String`. Data supplied by Events or other triggers in AWS will be JSON strings sent as the raw string value to your function. You must deserialize that string inside your function. Your return value must also be a string.

## Testing
There is a `dart-test.dart` file in the repo that provides a really, really simple code file that you can zip and upload as a Lambda function to test the custom runtime.

## History

### 1.0.0
Initial Release