import 'package:http/browser_client.dart';
import 'package:web/web.dart' as web;

const browserTransport = true;
BrowserClient createClient() => BrowserClient()..withCredentials = true;

bool hadBrowserSession(String key) {
  try {
    return web.window.localStorage.getItem(key) == '1';
  } catch (_) {
    return false;
  }
}

void markBrowserSession(String key, bool value) {
  try {
    if (value) {
      web.window.localStorage.setItem(key, '1');
    } else {
      web.window.localStorage.removeItem(key);
    }
  } catch (_) {}
}
