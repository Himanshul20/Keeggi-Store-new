import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:sixam_mart_store/data/api/api_client.dart';
import 'package:sixam_mart_store/data/model/response/profile_model.dart';
import 'package:sixam_mart_store/util/app_constants.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as Http;

import '../../view/base/custom_snackbar.dart';


class AuthRepo {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  AuthRepo({@required this.apiClient, @required this.sharedPreferences});

  Future<Response> login(String email, String password) async {
    return await apiClient.postData(AppConstants.LOGIN_URI, {"email": email, "password": password});
  }

  Future<Response> getProfileInfo() async {
    return await apiClient.getData(AppConstants.PROFILE_URI);
  }

  Future<Response> updateProfile(ProfileModel userInfoModel, Uint8List data, String token) async {
    Map<String, String> _fields = Map();
    _fields.addAll(<String, String>{
      '_method': 'put', 'f_name': userInfoModel.fName, 'l_name': userInfoModel.lName,
      'phone': userInfoModel.phone, 'token': getUserToken()
    });
    return await apiClient.postMultipartData(
      AppConstants.UPDATE_PROFILE_URI, _fields, [MultipartBody('image', data)],
    );
  }

  Future<Response> changePassword(ProfileModel userInfoModel, String password) async {
    return await apiClient.postData(AppConstants.UPDATE_PROFILE_URI, {'_method': 'put', 'f_name': userInfoModel.fName,
      'l_name': userInfoModel.lName, 'phone': userInfoModel.phone, 'password': password, 'token': getUserToken()});
  }

  Future<Response> updateToken() async {
    String _deviceToken;
    if (GetPlatform.isIOS) {
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true, announcement: false, badge: true, carPlay: false,
        criticalAlert: false, provisional: false, sound: true,
      );
      if(settings.authorizationStatus == AuthorizationStatus.authorized) {
        _deviceToken = await _saveDeviceToken();
      }
    }else {
      _deviceToken = await _saveDeviceToken();
    }
    if(!GetPlatform.isWeb) {
      FirebaseMessaging.instance.subscribeToTopic(AppConstants.TOPIC);
      FirebaseMessaging.instance.subscribeToTopic(sharedPreferences.getString(AppConstants.ZONE_TOPIC));
    }
    return await apiClient.postData(AppConstants.TOKEN_URI, {"_method": "put", "token": getUserToken(), "fcm_token": _deviceToken});
  }

  Future<String> _saveDeviceToken() async {
    String _deviceToken = '';
    if(!GetPlatform.isWeb) {
      _deviceToken = await FirebaseMessaging.instance.getToken();
    }
    if (_deviceToken != null) {
      print('--------Device Token---------- '+_deviceToken);
    }
    return _deviceToken;
  }

  Future<Response> forgetPassword(String email) async {
    return await apiClient.postData(AppConstants.FORGET_PASSWORD_URI, {"email": email});
  }

  Future<Response> verifyToken(String email, String token) async {
    return await apiClient.postData(AppConstants.VERIFY_TOKEN_URI, {"email": email, "reset_token": token});
  }

  Future<Response> resetPassword(String resetToken, String email, String password, String confirmPassword) async {
    return await apiClient.postData(
      AppConstants.RESET_PASSWORD_URI,
      {"_method": "put", "email": email, "reset_token": resetToken, "password": password, "confirm_password": confirmPassword},
    );
  }

  Future<bool> saveUserToken(String token, String zoneTopic) async {
    apiClient.updateHeader(token, sharedPreferences.getString(AppConstants.LANGUAGE_CODE), null);
    sharedPreferences.setString(AppConstants.ZONE_TOPIC, zoneTopic);
    return await sharedPreferences.setString(AppConstants.TOKEN, token);
  }

  void updateHeader(int moduleID) {
    apiClient.updateHeader(
      sharedPreferences.getString(AppConstants.TOKEN), sharedPreferences.getString(AppConstants.LANGUAGE_CODE), moduleID,
    );
  }

  String getUserToken() {
    return sharedPreferences.getString(AppConstants.TOKEN) ?? "";
  }

  bool isLoggedIn() {
    return sharedPreferences.containsKey(AppConstants.TOKEN);
  }

  Future<bool> clearSharedData() async {
    if(!GetPlatform.isWeb) {
      apiClient.postData(AppConstants.TOKEN_URI, {"_method": "put", "token": getUserToken(), "fcm_token": '@'});
      FirebaseMessaging.instance.unsubscribeFromTopic(sharedPreferences.getString(AppConstants.ZONE_TOPIC));
    }
    await sharedPreferences.remove(AppConstants.TOKEN);
    await sharedPreferences.remove(AppConstants.USER_ADDRESS);
    return true;
  }

  Future<void> saveUserNumberAndPassword(String number, String password) async {
    try {
      await sharedPreferences.setString(AppConstants.USER_PASSWORD, password);
      await sharedPreferences.setString(AppConstants.USER_NUMBER, number);
    } catch (e) {
      throw e;
    }
  }

  String getUserNumber() {
    return sharedPreferences.getString(AppConstants.USER_NUMBER) ?? "";
  }

  String getUserPassword() {
    return sharedPreferences.getString(AppConstants.USER_PASSWORD) ?? "";
  }

  bool isNotificationActive() {
    return sharedPreferences.getBool(AppConstants.NOTIFICATION) ?? true;
  }

  void setNotificationActive(bool isActive) {
    if(isActive) {
      updateToken();
    }else {
      if(!GetPlatform.isWeb) {
        FirebaseMessaging.instance.unsubscribeFromTopic(AppConstants.TOPIC);
        FirebaseMessaging.instance.unsubscribeFromTopic(sharedPreferences.getString(AppConstants.ZONE_TOPIC));
      }
    }
    sharedPreferences.setBool(AppConstants.NOTIFICATION, isActive);
  }

  Future<bool> clearUserNumberAndPassword() async {
    await sharedPreferences.remove(AppConstants.USER_PASSWORD);
    return await sharedPreferences.remove(AppConstants.USER_NUMBER);
  }

  Future<Response> toggleStoreClosedStatus() async {

    return await apiClient.postData(AppConstants.UPDATE_VENDOR_STATUS_URI, {});

    // return await apiClient.postData(AppConstants.TEMPORARILY_STORE_CLOSED, {"store_id":"64","temp_close_bydate_status":"1","close_from":"2022-09-22","close_to":"2022-09-25"});
  }


  Future<String> toggleStoreStatus(String store_id) async {
    var request = Http.Request('GET', Uri.parse('https://eastern.keeggi.in/api/get_close_store_status.php?storeid=${store_id}'));

   // return await request.send();
    Http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      String test = await response.stream.bytesToString();
      return test ;
      print(test);

    }
    else {

      print(response.reasonPhrase);
    }

  }
    Future<Response> toggleStoreClosedStatusFTD(String store_id, String fromdate, String todate,int status) async {

    var request = Http.MultipartRequest('POST', Uri.parse('https://eastern.keeggi.in/api/close_store.php'));
    request.fields.addAll({
      'temp_close_bydate_status': status.toString(),
      'close_from': fromdate,
      'close_to': todate,
      'store_id': store_id
    });


    Http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var message = jsonDecode(await response.stream.bytesToString());

      showCustomSnackBar(message["status"], isError: false);
      // showCustomSnackBar(await response.stream.bytesToString(), isError: false);

      print(await response.stream.bytesToString());
    }
    else {
      print(response.reasonPhrase);
    }

  }

}
