#include "session_storage.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <wincred.h>

#include <string>

namespace {
using Value = flutter::EncodableValue;
using MethodResult = flutter::MethodResult<Value>;

const std::string* ReadString(const flutter::EncodableMap* args,
                              const char* name) {
  if (!args) return nullptr;
  const auto value = args->find(Value(name));
  return value == args->end() ? nullptr : std::get_if<std::string>(&value->second);
}

void ReadCredential(const std::wstring& name, MethodResult& result) {
  PCREDENTIALW credential = nullptr;
  if (!CredReadW(name.c_str(), CRED_TYPE_GENERIC, 0, &credential)) {
    if (GetLastError() == ERROR_NOT_FOUND) {
      result.Success();
    } else {
      result.Error("credential_read_failed");
    }
    return;
  }
  std::string token(reinterpret_cast<const char*>(credential->CredentialBlob),
                    credential->CredentialBlobSize);
  CredFree(credential);
  result.Success(Value(token));
}

void WriteCredential(std::wstring& name, std::string token,
                     MethodResult& result) {
  if (token.empty() || token.size() > CRED_MAX_CREDENTIAL_BLOB_SIZE) {
    result.Error("invalid_token");
    return;
  }
  CREDENTIALW credential{};
  credential.Type = CRED_TYPE_GENERIC;
  credential.TargetName = name.data();
  credential.CredentialBlob =
      reinterpret_cast<LPBYTE>(token.data());
  credential.CredentialBlobSize = static_cast<DWORD>(token.size());
  credential.Persist = CRED_PERSIST_LOCAL_MACHINE;
  if (CredWriteW(&credential, 0)) {
    result.Success();
  } else {
    result.Error("credential_write_failed");
  }
}
}

void RegisterSessionStorage(flutter::BinaryMessenger* messenger) {
  flutter::MethodChannel<Value> channel(
      messenger, "frizeraj/session_storage",
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler([](const auto& call, auto result) {
    const auto* args = call.arguments()
                           ? std::get_if<flutter::EncodableMap>(call.arguments())
                           : nullptr;
    const auto* key = ReadString(args, "key");
    if (!key || key->empty() || key->size() > 256 ||
        key->find_first_not_of(
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.:/[]") !=
            std::string::npos) {
      result->Error("invalid_key");
      return;
    }
    std::wstring name = L"Frizeraj/session/";
    name.append(key->begin(), key->end());
    if (call.method_name() == "read") {
      ReadCredential(name, *result);
    } else if (call.method_name() == "write") {
      const auto* token = ReadString(args, "token");
      if (token) {
        WriteCredential(name, *token, *result);
      } else {
        result->Error("invalid_token");
      }
    } else if (call.method_name() == "clear") {
      if (CredDeleteW(name.c_str(), CRED_TYPE_GENERIC, 0) ||
          GetLastError() == ERROR_NOT_FOUND) {
        result->Success();
      } else {
        result->Error("credential_delete_failed");
      }
    } else {
      result->NotImplemented();
    }
  });
}
