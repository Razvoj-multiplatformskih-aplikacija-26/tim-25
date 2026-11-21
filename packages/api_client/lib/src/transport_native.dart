import 'package:http/http.dart' as http;

const browserTransport = false;
http.Client createClient() => http.Client();

bool hadBrowserSession(String key) => false;
void markBrowserSession(String key, bool value) {}
