import "dart:convert";
import "dart:js_util" as js_util;
import "dart:html" as html;

Future<Map<String, dynamic>?> performWebGoogleSignIn() async {
  try {
    if (js_util.hasProperty(html.window, "firebaseGoogleSignIn")) {
      final jsPromise = js_util.callMethod(html.window, "firebaseGoogleSignIn", []);
      final resultString = await js_util.promiseToFuture<dynamic>(jsPromise);
      final data = json.decode(resultString.toString());
      return data is Map<String, dynamic> ? data : null;
    }
  } catch (e) {
    return {"success": false, "error": e.toString()};
  }
  return null;
}
