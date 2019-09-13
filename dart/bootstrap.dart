library dart_handler_loader;

import "{{LAMBDA_HANDLER_PATH}}";
import 'dart:io' show Platform, HttpClient, HttpClientRequest, HttpClientResponse;
import "dart:mirrors";
import "dart:convert";
import "dart:async";

Future<void> main(List<String> args) async {
  // This is in the format file.handler where the file does not have an extension
  // The handler will be in lib.class.method format
  String handler = args[0];
  List<String> parts = handler.split(".");

  Symbol library = Symbol.empty;
  Symbol className = Symbol.empty;
  Symbol methodName = Symbol.empty;

  if (parts.length == 3)
  {
    library = new Symbol(parts[0]);
    className = new Symbol(parts[1]);
    methodName = new Symbol(parts[2]);
  }
  else if (parts.length == 2)
  {
    className = new Symbol(parts[0]);
    methodName = new Symbol(parts[1]);
  }
  else 
  {
    throw new Exception("The handler ${handler} was not in the expected format.");
  }

  MirrorSystem mirrors = currentMirrorSystem();
  ClassMirror classMirror = mirrors.findLibrary(library).declarations[className];

  InstanceMirror im = classMirror.newInstance(Symbol.empty, []);
  
  // Dart can't parse json to an object, so this
  // part can't be used to convert the input string 
  // data to an object, the customer supplied function
  // must deal with converting the json
  //
  // MethodMirror mm = im.type.instanceMembers.values.firstWhere((MethodMirror method) =>  method.simpleName == methodName);
  // ParameterMirror pm = mm.parameters.first;
  // TypeMirror type = pm.type;

  // Process the requests from the lambda runtime api
  HttpClient client = new HttpClient();

  try
  {
    while(true) 
    {  
      String runtimeApi = "http://${Platform.environment["AWS_LAMBDA_RUNTIME_API"]}/2018-06-01/runtime/invocation/next";

      // Get the event data
      HttpClientRequest request = await client.getUrl(Uri.parse(runtimeApi));
      HttpClientResponse response = await request.close();
      String requestId = response.headers["Lambda-Runtime-Aws-Request-Id"][0]; 
      String eventData = await response.transform(utf8.decoder).join();

      // Invoke the customer code with the event data and get the response
      String ret = im.invoke(methodName, [eventData]).reflectee;

      // Send the response back to the runtime api
      String responseApi = "http://${Platform.environment["AWS_LAMBDA_RUNTIME_API"]}/2018-06-01/runtime/invocation/${requestId}/response";
      HttpClientRequest postRequest = await client.postUrl(Uri.parse(responseApi));
      postRequest.write(ret);
      HttpClientResponse postResponse = await postRequest.close();
    }
  }
  finally
  {
    client.close();
  }
}